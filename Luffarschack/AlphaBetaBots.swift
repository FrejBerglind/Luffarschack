//
//  AlphaBetaBots.swift
//  Luffarschack1
//
//  Created by Frej Berglind on 2018-01-26.
//  Copyright © 2018 Frej Berglind. All rights reserved.
//

import Foundation

/** 1st gen alpha beta bot
 */
struct Alpha: Player{
    let board: Board
    let xOrO: XorO
    let description = "Alpha"
    let n=9 //Antalet drag i simuleringar
    let tol=2 // Tolerans för bra drag
    let limit=20
    
    func nextMove()->Move {
        print("Alpha: ")
        if(board.isEmpty){
            return Move(row: board.side/2,col: board.side/2,xOrO: xOrO)
        }
        else{
            let b=bestMoves()
            if b.isEmpty {
                return board.rankedBoard().bestMoves(for: xOrO).randomElement()
            } else{
                print(b)
                return b.randomElement()
            }
        }
    }
    
    /** Best moves according to this bot
     */
    func bestMoves()->[Move]{
        let rb=board.rankedBoard()
        var bestMoves: [Move]=[]
        var max = Int.min+1
        let gm=rb.goodMoves(for: xOrO, tol, limit)
        if gm.count == 1 {
            return rb.bestMoves(for: xOrO)
        }
        for move in gm{
            print(move)
            if rb.winningMove(move){
                return [move]
            }
            let copy=rb.copy()
            copy.put(move)
            //let r=ranking(copy, alpha: Int.min, beta: Int.max,n, playersTurn: false)
            let r=ranking(copy, alpha: max-1, beta: Int.max,n, playersTurn: false)
            print(r)
            if r>max{
                max=r
                bestMoves=[move]
            }
            else if r==max{
                bestMoves.append(move)
            }
        }
        print(max)
        return bestMoves
    }
    
    /** Alpha Beta pruning:
     */
    func ranking(_ rb: RankedBoard, alpha: Int, beta: Int,_ n: Int, playersTurn: Bool)->Int{
        if n==0{
            return rb.ranking(for: xOrO)
        }
        if playersTurn {
            var r=Int.min
            var a=alpha
            for move in rb.goodMoves(for: xOrO, tol, limit){
                if rb.winningMove(move){
                    return 1000000*(n+2) //Win!
                }
                let copy=rb.copy()
                copy.put(move)
                r = max(r,ranking(copy, alpha: a, beta: beta,n-1, playersTurn: false))
                a=max(a,r)
                if beta<=a {
                    break
                }
            }
            return r
        } else {
            var r=Int.max
            var b=beta
            for move in rb.goodMoves(for: opponent(xOrO), tol, limit){
                if rb.winningMove(move){
                    return -1000000*(n+2) //Loose
                }
                let copy=rb.copy()
                copy.put(move)
                r = min(r,ranking(copy, alpha: alpha, beta: b,n-1, playersTurn: true))
                b=min(b,r)
                if b<=alpha {
                    break
                }
            }
            return r
        }
    }
}

/** 2nd gen alpha beta bot
 */
struct Beta: Player{
    let board: Board
    let xOrO: XorO
    let description = "Beta"
    let n=9 //Antalet drag i simuleringar
    let tol=2 // Tolerans för bra drag
    let limit=20
    
    func nextMove()->Move {
        print("Beta")
        if(board.isEmpty){
            return Move(row: board.side/2,col: board.side/2,xOrO: xOrO)
        }
        else{
            let b=bestMoves()
            if b.isEmpty {
                return board.rankedBoard().bestMoves(for: xOrO).randomElement()
            } else{
                print(b)
                return b.randomElement()
            }
        }
    }
    
    /** Best moves according to this bot.
     */
    func bestMoves()->[Move]{
        let rb=board.rankedBoard()
        var bestMoves: [Move]=[]
        var max = Int.min+1
        let gm=rb.goodMoves(for: xOrO, tol, limit)
        if gm.count == 1 {
            return rb.bestMoves(for: xOrO)
        }
        for move in gm{
            print(move)
            if rb.winningMove(move){
                return [move]
            }
            let copy=rb.copy()
            copy.put(move)
            //let r=ranking(copy, alpha: Int.min, beta: Int.max,n, playersTurn: false)
            let r=ranking(copy, alpha: max-1, beta: Int.max,n, playersTurn: false)
            print(r)
            if r>max{
                max=r
                bestMoves=[move]
            }
            else if r==max{
                bestMoves.append(move)
            }
        }
        print(max)
        return bestMoves
    }
    
    /** Alpha Beta pruning:
     */
    func ranking(_ rb: RankedBoard, alpha: Int, beta: Int,_ n: Int, playersTurn: Bool)->Int{
        if playersTurn {
            if n==0{
                return Beta.ranking(of: rb, for: xOrO)
            }
            var r=Int.min
            var a=alpha
            for move in rb.goodMoves(for: xOrO, tol, limit){
                if rb.winningMove(move){
                    return 1000000*(n+2) //Win!
                }
                let copy=rb.copy()
                copy.put(move)
                r = max(r,ranking(copy, alpha: a, beta: beta,n-1, playersTurn: false))
                a=max(a,r)
                if beta<=a {
                    break
                }
            }
            return r
        } else {
            if n==0{
                return -Beta.ranking(of: rb, for: opponent(xOrO))
            }
            var r=Int.max
            var b=beta
            for move in rb.goodMoves(for: opponent(xOrO), tol, limit){
                if rb.winningMove(move){
                    return -1000000*(n+2) //Loose
                }
                let copy=rb.copy()
                copy.put(move)
                r = min(r,ranking(copy, alpha: alpha, beta: b,n-1, playersTurn: true))
                b=min(b,r)
                if b<=alpha {
                    break
                }
            }
            return r
        }
    }
    
    /** Rankes the board with clever method.
     */
    static func ranking(of rb: RankedBoard, for player: XorO)->Int{
        var bm1=rb.bestMoves(for: player)
        if(bm1.isEmpty){
            return 0
        }
        let copy = rb.copy()
        copy.put(bm1[0])
        let bm2=rb.bestMoves(for: opponent(player))
        if(bm2.isEmpty){
            return rb.offensiveRanking(bm1[0])
        }
        return rb.offensiveRanking(bm1[0])-copy.offensiveRanking(bm2[0])
    }
}

