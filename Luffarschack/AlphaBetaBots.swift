//
//  AlphaBetaBots.swift
//  Luffarschack1
//
//  Created by Frej Berglind on 2018-01-26.
//  Copyright © 2018 Frej Berglind. All rights reserved.
//

import Foundation

private let N=9 //Nbr of moves in simulation
private let tol=2 // Tolerans för bra drag
private let limit=20

func AlphaBeta(_ board: Board, _ xOrO: XorO, rank: (RankedBoard, XorO)->Int)->Move {
    if(board.isEmpty){
        return Move(row: board.side/2,col: board.side/2,xOrO: xOrO)
    }
    else {
        let b=bestMoves(board, xOrO, rank)
        if b.isEmpty {
            return board.rankedBoard().bestMoves(for: xOrO).randomElement()
        } else {
            print(b)
            return b.randomElement()
        }
    }
}

/** Best moves based on Alpha-Beta Pruning
 */
func bestMoves(_ board: Board, _ xOrO: XorO, _ rank: (RankedBoard, XorO)->Int)->[Move]{
    let rb=board.rankedBoard()
    var bestMoves: [Move]=[]
    var max = Int.min+1
    let gm = rb.goodMoves(for: xOrO, tol, limit)
    if gm.count == 1 {
        return gm
    }
    var shittyMoves=true
    for move in gm{
        print(move)
        if rb.winningMove(move){
            return [move]
        }
        if rb.ranking(of: move)<30 && shittyMoves{
            bestMoves.append(move)
            continue
        } else {
            shittyMoves=false
        }
        let copy=rb.copy()
        copy.put(move)
        let r=ranking(copy, alpha: max-1, beta: Int.max,N, playersTurn: false, xOrO, rank)
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
func ranking(_ rb: RankedBoard, alpha: Int, beta: Int,_ n: Int, playersTurn: Bool, _ xOrO: XorO, _ rank: (RankedBoard, XorO)->Int)->Int{
    if n==0{
        return rank(rb, xOrO)
    }
    if playersTurn {
        var r=Int.min
        var a=alpha
        for move in rb.goodMoves(for: xOrO, tol, limit){
            if rb.winningMove(move){
                return 10000000*(n+2) //Win!
            }
            let copy=rb.copy()
            copy.put(move)
            r = max(r,ranking(copy, alpha: a, beta: beta,n-1, playersTurn: false, xOrO, rank))
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
                return -10000000*(n+2) //Loose
            }
            let copy=rb.copy()
            copy.put(move)
            r = min(r,ranking(copy, alpha: alpha, beta: b,n-1, playersTurn: true, xOrO, rank))
            b=min(b,r)
            if b<=alpha {
                break
            }
        }
        return r
    }
}


/** 1st gen alpha beta bot
 */
struct Alpha: Player{
    let board: Board
    let xOrO: XorO
    let description = "Alpha"
    
    func nextMove()->Move {
        print(description+":")
        return AlphaBeta(board, xOrO, rank: Alpha.ranking)
    }
    
    /** Rankes the board with a quite clever method.
     */
    private static func ranking(of rb: RankedBoard, for player: XorO)->Int{
        return rb.ranking(for: player)
    }
}

/** 2nd gen alpha beta bot
 */
struct Beta: Player{
    let board: Board
    let xOrO: XorO
    let description = "Beta"
    
    func nextMove()->Move {
        print(description+":")
        return AlphaBeta(board, xOrO, rank: Beta.ranking)
    }
    
    /** Rankes the board with clever method.
     */
    private static func ranking(of rb: RankedBoard, for player: XorO)->Int{
        var bm1=rb.bestMoves(for: player)
        if(bm1.isEmpty){
            return 0
        }
        let copy = rb.copy()
        copy.put(bm1[0])
        let bm2=copy.bestMoves(for: opponent(player))
        if(bm2.isEmpty){
            return rb.offensiveRanking(bm1[0])
        }
        return rb.offensiveRanking(bm1[0])-copy.offensiveRanking(bm2[0])
    }
}

struct Gamma: Player{
    let board: Board
    let xOrO: XorO
    let description = "Gamma"
    
    func nextMove()->Move {
        return AlphaBeta(board, xOrO, rank: Gamma.ranking)
    }
    
    /** Rankes the board with clever method.
     */
    private static func ranking(of rb: RankedBoard, for player: XorO)->Int{
        let r=rb.rbX.rb.reduce([], +).reduce(0,+)-rb.rbO.rb.reduce([], +).reduce(0,+)
        switch (player) {
        case .x:
            return r
        case.o:
            return -r
        default:
            return 0
        }
    }
}

