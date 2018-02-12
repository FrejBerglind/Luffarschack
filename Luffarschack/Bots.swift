//
//  MasterBot.swift
//  Luffarschack
//
//  Created by Frej Berglind on 2017-02-26.
//  Copyright © 2017 Frej Berglind. All rights reserved.
//

import Foundation

/** Like mediumbot, but uses alphabeta-pruning to find winning moves
 */
struct MasterBot: Player{
    let board: Board
    let xOrO: XorO
    let description = "MasterBot"
    let n=15 //nbr of moves in simulations
    
    // Limits for good moves:
    let tol=2
    let limit=20
    
    func nextMove()->Move {
        if(board.isEmpty){
            return Move(row: board.side/2,col: board.side/2,xOrO: xOrO)
        }
        else{
            let bm=bestMoves()
            print(bm)
            return bm.randomElement()
        }
    }
    
    /** Best moves for the player
     */
    func bestMoves()->[Move]{
        let rb=board.rankedBoard()
        var bestMoves: [Move]=[]
        var m = -1000
        for move in rb.goodMoves(for: xOrO, tol, limit){
            print(move)
            let copy=rb.copy()
            copy.put(move)
            let r=canWin(copy, alpha: m-1, beta: Int.max,n, playersTurn: false, lastMoveByPlayer: move, player: xOrO)
            if r>m{
                m=r
                bestMoves=[move]
            }
            else if r==m{
                bestMoves.append(move)
            }
        }
        if m>0 {
            print("Jag kommer vinna om \(n-m) drag!")
        } else {
            m = 0
            var safeMoves: [Move]=[]
            for move in rb.goodMoves(for: xOrO, tol, limit){
                let copy=rb.copy()
                copy.put(move)
                let r=canWin(copy, alpha: m-1, beta: Int.max,n, playersTurn: true, lastMoveByPlayer: nil, player: opponent(xOrO))
                if r>m{
                    m=r
                }
                else if r==0 {
                    safeMoves.append(move)
                }
            }
            bestMoves=rb.bestMoves(for: xOrO)
            if m>0{
                if safeMoves.isEmpty {
                    print("Jag kommer förlora om \(n-m) drag!")
                }
                else if !safeMoves.containsAll(of:
                    bestMoves) {
                    print("Jag kunde förlorat om \(n-m) drag!")
                    bestMoves=safeMoves
                }
            }
        }
        print("BestMovesfor ger: \(rb.bestMoves(for: xOrO))")
        print(m)
        return bestMoves
    }
    
    /** Checks if player can win in n moves, alpha beta pruning
     */
    func canWin(_ rb: RankedBoard, alpha: Int, beta: Int,_ n: Int, playersTurn: Bool, lastMoveByPlayer: Move?, player: XorO)->Int{
        let r=rb.ranking(for: player)
        if n==0{
            return 0
        }
        if playersTurn {
            if r>50000 {
                return n //Win!
            }
            var rank=Int.min;
            var a=alpha
            for move in rb.goodMoves(for: player, tol, limit){
                if move.isRelatedTo(lastMoveByPlayer){
                    let copy=rb.copy()
                    copy.put(move)
                    rank=max(rank,canWin(copy, alpha: a, beta: beta, n-1, playersTurn: false, lastMoveByPlayer: move, player: player))
                    a=max(a,rank)
                    if beta<=a {
                        break
                    }
                }
                else if rb.ranking(of: move)>50000{
                    let copy=rb.copy()
                    copy.put(move)
                    rank=max(rank,canWin(copy, alpha: a, beta: beta, n-1, playersTurn: false, lastMoveByPlayer: lastMoveByPlayer, player: player))
                    a=max(a,rank)
                    if beta<=a {
                        break
                    }
                }
            }
            return rank
        } else {
            if r < -50000 {
                return  0 //Loose!
            }
            var rank=Int.max
            var b=beta
            for move in rb.goodMoves(for: opponent(player), tol, limit){
                let copy=rb.copy()
                copy.put(move)
                rank = min(r,rank,canWin(copy, alpha: alpha, beta: b, n-1, playersTurn: true, lastMoveByPlayer: lastMoveByPlayer, player: player))
                b=min(b,rank)
                if b<=0||b<=alpha {
                    return 0
                }
            }
            return rank
        }
    }
}

/** A bot using RankedBoard to find the best moves.
 */
struct MediumBot: Player {
    let board: Board
    let xOrO: XorO
    let description = "MediumBot"
    
    func nextMove()->Move {
        if(board.isEmpty){
            return Move(row: board.side/2,col: board.side/2,xOrO: xOrO)
        }
        else{
            let moves=bestMoves()
            if moves.isEmpty{
                return Move(board.openCells().randomElement(), xOrO)
            }
            return moves.randomElement()
        }
    }
    
    /** Best moves for the player.
     */
    func bestMoves()->[Move]{
        return board.rankedBoard().bestMoves(for: xOrO)
    }
}

/** A bot who simply tries to get/block as many in a row as possible.
 */
struct EasyBot: Player {
    let board: Board
    let xOrO: XorO
    let description = "EasyBot"
    
    func nextMove()->Move {
        if(board.isEmpty){
            return Move(row: board.side/2,col: board.side/2,xOrO: xOrO)
        }
        else{
            let moves=bestMoves()
            if moves.isEmpty{
                return Move(board.openCells().randomElement(), xOrO)
            }
            return moves.randomElement()
        }
    }
    
    /** Best moves according to the player.
     */
    func bestMoves()->[Move]{
        var bestMoves: [Move]=[]
        let other=opponent(xOrO)
        for n in (1...4).reversed() {
            for rc in [[0,1],[1,0],[1,1],[1,-1]]{
                let r=rc[0]
                let c=rc[1]
                var max=0
                for r0 in 0..<board.side{
                    loop: for c0 in 0..<board.side{
                        var moves: [Move]=[]
                        var count=0
                        var consecutiveEmpty=0
                        for d in 0...4{
                            let row=r0+r*d
                            let col=c0+c*d
                            if !board.onBoard(row: row,col: col) { continue loop }
                            switch(board.get(row,col)){
                            case xOrO: if d%4==0 {
                                count+=1
                            } else {
                                count+=2
                            }
                            consecutiveEmpty=0
                            case other: continue loop
                            default: consecutiveEmpty+=1
                            if(consecutiveEmpty > 2){
                                if !moves.isEmpty{
                                    moves.removeFirst()
                                }
                            }else{
                                moves.append(Move(row: row, col: col, xOrO: xOrO))
                                }
                            }
                        }
                        if(count>=(2*n-1)){
                            if(count==max){
                                bestMoves.append(contentsOf: moves)
                            } else if (count>max){
                                max = count
                                bestMoves=moves
                            }
                        }
                    }
                }
            }
            if !bestMoves.isEmpty {
                print("\(n) i rad, offensivt")
                return bestMoves
            }
            for rc in [[0,1],[1,0],[1,1],[1,-1]]{
                let r=rc[0]
                let c=rc[1]
                var max=0
                for r0 in 0..<board.side{
                    loop: for c0 in 0..<board.side{
                        var moves: [Move]=[]
                        var count=0
                        var consecutiveEmpty=0
                        for d in 0...n{
                            let row=r0+r*d
                            let col=c0+c*d
                            if !board.onBoard(row: row,col: col) {continue loop}
                            
                            switch(board.get(row,col)){
                            case other: if d%4==0 {
                                count+=1
                            } else {
                                count+=2
                            }
                            consecutiveEmpty=0
                            case xOrO: continue loop
                            default: consecutiveEmpty+=1
                            if(consecutiveEmpty > 2){
                                if !moves.isEmpty{
                                    moves.removeFirst()
                                }
                            }else{
                                moves.append(Move(row: row, col: col, xOrO: xOrO))
                                }
                            }
                        }
                        if(count>=(2*n-1)){
                            if(count==max){
                                bestMoves.append(contentsOf: moves)
                            } else if (count>max){
                                max = count
                                bestMoves=moves
                            }
                        }
                    }
                }
            }
            if !bestMoves.isEmpty {
                print("\(n) i rad, defensivt")
                return bestMoves
            }
        }
        return bestMoves
    }
}

/** The opponent of xOrO
 */
func opponent(_ xOrO: XorO)->XorO{
    switch(xOrO){
    case .x: return .o
    case .o: return .x
    default: return .empty
    }
}

extension Array{
    /** A random element in the vector
     */
    func randomElement() -> Element{
        return self[Int(arc4random_uniform(UInt32(count)))]
    }
}

extension Array where Element: Equatable {
    func containsAll(of array: [Element]) -> Bool {
        for item in array {
            if !self.contains(item) { return false }
        }
        return true
    }
}

extension Move: Equatable {
    static func ==(lhs: Move, rhs: Move) -> Bool {
        return lhs.col==rhs.col && lhs.row==rhs.row && lhs.xOrO==rhs.xOrO
    }
}

extension Move{
    func isRelatedTo(_ move: Move?)->Bool{
        if let m=move {
            let dr=abs(row-m.row)
            let dc=abs(col-m.col)
            return dr<5&&dc<5&&(dr==0||dc==0||dr/dc==1)
        }
        return true
    }
}

extension Board{
    func openCells() -> [Cell]{
        var cells: [Cell] = []
        for row in 0..<side{
            for col in 0..<side{
                if(board[row][col] == .empty){
                    cells.append(Cell(row: row, col: col))
                }
            }
        }
        return cells
    }
}
