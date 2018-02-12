//
//  Basics.swift
//  Luffarschack
//
//  Created by Frej Berglind on 2017-02-26.
//  Copyright © 2017 Frej Berglind. All rights reserved.
//

import Foundation

/** Basic values of the board
 */
enum XorO{
    case x, o, empty
}

extension XorO : CustomStringConvertible{
    var description: String{
        switch(self){
        case .empty:
            return "-"
        case .x:
            return "x"
        case .o:
            return "o"
        }
    }
}

/** A move in the game
 */
struct Move {
    let row: Int
    let col: Int
    let xOrO: XorO
    
    init(_ cell: Cell, _ xOrO: XorO){
        row=cell.row
        col=cell.col
        self.xOrO=xOrO
    }
    
    init(row: Int, col: Int, xOrO: XorO){
        self.row=row
        self.col=col
        self.xOrO=xOrO
    }
}

/** A cell on the board
 */
struct Cell {
    let row: Int
    let col: Int
}

/** The board for the game
 */
class Board {
    var board: [[XorO]]
    let side: Int
    var isEmpty=true
    init(side: Int) {
        self.side=side
        board = Array(repeating:Array(repeating:XorO.empty, count: side),count: side)
    }
    
    func put(_ move: Move){
        board[move.row][move.col]=move.xOrO
        isEmpty=false
    }
    
    func get(_ row: Int, _ col: Int)->XorO{
        return board[row][col]
    }
    
    func get(_ cell: Cell)->XorO{
        return board[cell.row][cell.col]
    }
    
    /** Resets the board  for a new game
     */
    func clear(){
        isEmpty=true
        board = Array(repeating:Array(repeating:XorO.empty, count: side),count: side)
    }
}


extension Board {
    
    /** Prints the board
     */
    func printBoard(){
        for row in board{
            for cell in row {
                print(cell, terminator: " ")
            }
            print()
        }
        print()
    }
    
    /** Utility function for keeping track if (row,col) is on the board
     */
    func onBoard(row: Int, col: Int)->Bool{
        return (row<side&&col<side&&row>=0&&col>=0)
    }
}

extension Board {
    
    /**
     @Returns
     .x or .o if a player has won,
     nilif the game isn't over,
     .empty if it's a tie.
     */
    func win()->XorO?{
        for xOrO in [XorO.x, XorO.o]{
            for rc in [[0,1],[1,0],[1,1],[1,-1]]{
                let r=rc[0]
                let c=rc[1]
                for r0 in 0..<side{
                    loop: for c0 in 0..<side{
                        for d in 0...4{
                            let row=r0+r*d
                            let col=c0+c*d
                            if (!onBoard(row: row,col: col))||(get(row, col) != xOrO) {
                                continue loop
                            }
                        }
                        return xOrO
                    }
                }
            }
        }
        for xOrO in [XorO.x, XorO.o]{
            for rc in [[0,1],[1,0],[1,1],[1,-1]]{
                let r=rc[0]
                let c=rc[1]
                for r0 in 0..<side{
                    loop: for c0 in 0..<side{
                        for d in 0...4{
                            let row=r0+r*d
                            let col=c0+c*d
                            if (!onBoard(row: row,col: col))||(get(row, col) == xOrO) {
                                continue loop
                            }
                        }
                        return nil
                    }
                }
            }
        }
        return .empty
    }
}

/** A board that saves the history can undo moves
 */
class UndoBoard: Board{
    var oldMoves: [Move]=[]
    
    override func put(_ move: Move){
        oldMoves.append(move)
        super.put(move)
    }
    
    override func clear(){
        super.clear()
        oldMoves=[]
    }
    func undo()->Move? {
        if(!oldMoves.isEmpty){
            let m=oldMoves.popLast()!
            board[m.row][m.col]=XorO.empty
            return m
        }
        return nil
    }
}

/** Players in the game.
 */
protocol Player: CustomStringConvertible {
    /** Next move of the player.
     */
    func nextMove()->Move
}

