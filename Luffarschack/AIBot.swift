//
//  AIBot.swift
//  Luffarschack
//
//  Created by Frej Berglind on 2018-02-19.
//  Copyright © 2018 Frej Berglind. All rights reserved.
//

import Foundation

/** It's alive!
 */
class AIBot: Player{
    
    let board: Board
    let xOrO: XorO
    let description = "AIBot"
    var choices: [Choice]=[]
    
    init(_ board: Board, _ xOrO: XorO){
        self.board=board
        self.xOrO=xOrO
    }
    
    // Limits for good moves:
    let tol=2
    let limit=0
    
    func nextMove()->Move {
        if(board.isEmpty){
            return Move(row: board.side/2,col: board.side/2,xOrO: xOrO)
        }
        else{
            let (r, bm) = bestMoves()
            print(bm)
            let move=bm.randomElement()
            choices.append(Choice(board: board.intBoard(player: xOrO), move: move, ranking: r))
            return move
        }
    }
    
    /** Best moves for the player
     */
    func bestMoves()-> (Double,[Move]) {
        let rb=board.rankedBoard()
        var bestMoves: [Move]=[]
        var m: Double = 0
        let intBoard=board.intBoard(player: xOrO)
        for move in rb.goodMoves(for: xOrO, tol, limit){
            print(move)
            let copy=rb.copy()
            copy.put(move)
            let r=ranking(of: move, intBoard)
            if r>m{
                m=r
                bestMoves=[move]
            }
            else if r==m{
                bestMoves.append(move)
            }
        }
        
        return (m,bestMoves)
    }
    
    func ranking(of move: Move, _ board: [[Int]])-> Double {
        return 0.5
    }
}

struct Choice {
    let board: [[Int]];
    let move: Move;
    let ranking: Double;
}

extension Board{
    func intBoard(player: XorO) -> [[Int]] {
        var ib = Array(repeating:Array(repeating:0, count: side),count: side)
        for row in 0..<side {
            for col in 0..<side {
                switch board[row][col] {
                case player: ib[row][col] = 1
                case .empty: break
                default: ib[row][col] = -1
                }
            }
        }
        return ib
    }
}


