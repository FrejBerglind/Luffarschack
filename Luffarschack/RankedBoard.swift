//
//  RankedBoard.swift
//  Luffarschack
//
//  Created by Frej Berglind on 2017-02-27.
//  Copyright © 2017 Frej Berglind. All rights reserved.
//

//import Foundation

/** A board where each cell is ranked. */
class RankedBoard: Board{
    var rbX:RB
    var rbO:RB
    
    override init(side: Int){
        rbX=RB(XorO.x, side)
        rbO=RB(XorO.o, side)
        super.init(side: side)
    }
    
    override func put(_ move: Move){
        super.put(move)
        rbX.updateRanking(move , self)
        rbO.updateRanking(move , self)
    }
    
    /** List of the best moves for player*/
    func bestMoves(for player : XorO)-> [Move]{
        let this: RB
        let other: RB
        switch(player){
        case .x:
            this=rbX
            other=rbO
        case .o:
            this=rbO
            other=rbX
        default: return []
        }
        var bestMoves: [Move]=[]
        var max=1
        for row in 0..<side{
            for col in 0..<side{
                if this.rb[row][col]>90000 {
                    return [Move(row: row, col: col, xOrO: player)]
                }
                let ranking = (3*this.rb[row][col])/2+other.rb[row][col]
                if max<ranking {
                    max=ranking
                    bestMoves=[Move(row: row, col: col, xOrO: player)]
                }
                else if max==ranking{
                    bestMoves.append(Move(row: row, col: col, xOrO: player))
                }
            }
        }
        if bestMoves.isEmpty {
            for row in 0..<side{
                for col in 0..<side{
                    if board[row][col] == .empty{
                        bestMoves.append(Move(row: row, col: col, xOrO: player))
                    }
                }
            }
        }
        return bestMoves
    }
}

extension RankedBoard{
    
    /** Useful print for testing
     */
    func printRankings() {
        print("Rätt import!")
        printBoard()
        print("X:")
        for row in rbX.rb{
            for cell in row {
                print(cell, terminator: "\t")
            }
            print()
        }
        print()
        print("O:")
        for row in rbO.rb{
            for cell in row {
                print(cell, terminator: "\t")
            }
            print()
        }
        print()
        
    }
    
    /** @Returns the ranking of move
     */
    func ranking(of move: Move)->Int{
        let this: RB
        let other: RB
        switch(move.xOrO){
        case .x:
            this=rbX
            other=rbO
        case .o:
            this=rbO
            other=rbX
        default:
            return 0 //Ska inte kunna hända
        }
        return (3*this.rb[move.row][move.col])/2+other.rb[move.row][move.col]
    }
    
    /** Rankes the board by how offensive the best move is.
     */
    func ranking(for player: XorO)->Int{
        
        let bm=bestMoves(for: player)
        if(bm.isEmpty){
            return 0
        }
        let this: RB
        let other: RB
        switch(player){
        case .x:
            this=rbX
            other=rbO
        case .o:
            this=rbO
            other=rbX
        default: return -1
        }
        return this.rb[bm[0].row][bm[0].col]-other.rb[bm[0].row][bm[0].col]
    }
    
    /** True if move is a winning move
     */
    func winningMove(_ move: Move)->Bool{
        return offensiveRanking(move)>90000
    }
    
    /** Rankars the move by how offensive it is. */
    func offensiveRanking(_ move: Move)->Int{
        let this: RB
        switch(move.xOrO){
        case .x:
            this=rbX
        case .o:
            this=rbO
        default:
            return 0 //Ska inte kunna hända
        }
        return this.rb[move.row][move.col]
    }
    
    /** Selects good moves for player XorO
     */
    func goodMoves(for player: XorO, _ tol: Int, _ limit: Int)->[Move]{
        let this: RB
        let other: RB
        switch(player){
        case .x:
            this=rbX
            other=rbO
        case .o:
            this=rbO
            other=rbX
        default: return []
        }
        if let best=bestMoves(for: player).first{
            let r = best.row
            let c = best.col
            let max = (3*this.rb[r][c])/2+other.rb[r][c]
            var goodMoves: [Move]=[best]
            for row in 0..<side{
                for col in 0..<side{
                    if row==r&&col==c {continue}
                    let ranking = (3*this.rb[row][col])/2+other.rb[row][col]
                    if max<ranking*tol-limit {
                        goodMoves.append(Move(row: row, col: col, xOrO: player))
                    }
                }
            }
            return goodMoves
        }
        return []
    }
}

/** Ranks the cells of the board for player xOrO
 */
struct RB{
    var rb: [[Int]]
    let side: Int
    let  xOrO: XorO
    
    /** Creats RB of empty ranked board.
     */
    init(_ xOrO:XorO, _ side: Int){
        self.side=side
        rb = Array(repeating:Array(repeating:0, count: side),count: side)
        self.xOrO=xOrO
    }
    
    /** Updates the rankings of the cells nearby move.
     */
    mutating func updateRanking(_ move: Move, _ board: Board){
        rb[move.row][move.col]=0
        if(move.xOrO==xOrO){
            for rc in [[0,1],[1,0],[1,1],[1,-1]]{
                let r=rc[0]
                let c=rc[1]
                loop: for d0 in -4...0{
                    var sum=0
                    var list: [[Int]]=[]
                    for d in 0...4{
                        let row=move.row+r*(d0+d)
                        let col=move.col+c*(d0+d)
                        
                        if !(board.onBoard(row: row,col: col)) {
                            continue loop
                        }
                        
                        switch(board.get(row, col)){
                        case .empty: list.append([row,col])
                        case xOrO: sum+=1
                        default: continue loop
                        }
                    }
                    let ranking: Int
                    
                    if sum>3 {
                        ranking=100001-exp(sum-1)
                    }
                    else{
                        ranking=exp(sum)-exp(sum-1)
                    }
                    for cell in list{
                        rb[cell[0]][cell[1]]+=ranking
                    }
                }
            }
        } else {
            for rc in [[0,1],[1,0],[1,1],[1,-1]]{
                let r=rc[0]
                let c=rc[1]
                loop: for d0 in -4...0{
                    var sum=0
                    var list: [[Int]]=[]
                    for d in 0...4{
                        let row=move.row+r*(d0+d)
                        let col=move.col+c*(d0+d)
                        
                        if (d0+d==0){
                            continue //Ska inte räkna nya draget
                        }
                        
                        if !(board.onBoard(row: row,col: col)) {
                            continue loop
                        }
                        
                        switch(board.get(row, col)){
                        case .empty: list.append([row,col])
                        case xOrO: sum+=1
                        default: continue loop
                        }
                    }
                    if sum>0 {
                        let ranking: Int
                        if sum>3 {
                            ranking=100001+exp(sum)
                        }
                        else{
                            ranking=exp(sum)
                        }
                        for cell in list{
                            rb[cell[0]][cell[1]]-=ranking                        }
                    }
                }
            }
            
        }
        
    }
}

/** 5^n, 0 for n=0 */
private func exp(_ n: Int)->Int{
    if n<0 {return 0}
    var exp=1
    for _ in 0..<n{
        exp=exp*5
    }
    return exp
}

extension Board{
    /** Creates a ranked board out of the board
     */
    func rankedBoard()->RankedBoard{
        let rb=RankedBoard(side: side)
        for row in 0..<side{
            for col in 0..<side{
                if get(row, col) != .empty{
                    rb.put(Move(row: row, col: col, xOrO: get(row, col)))
                }
            }
        }
        return rb
    }
}

extension RankedBoard{
    /** Copies the RankedBoard
     */
    func copy()->RankedBoard{
        let rb=RankedBoard(side: side);
        rb.board=board
        rb.rbO=rbO
        rb.rbX=rbX
        rb.isEmpty=isEmpty
        return rb
    }
}


