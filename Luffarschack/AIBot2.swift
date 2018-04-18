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
class AIBot2: Player{
    
    var board: Board
    let xOrO: XorO
    let description = "AIBot"
    var choices: [Choice]=[]
    var opponentsChoices: [Choice]=[]
    var data: [[[Float]]]=[]
    var outputs: [[[Float]]]=[]
    // Limits for good moves:
    
    let batchSize = 16
    let N = 10 //Nbr of saved games for training
    let tol=2
    let limit=50
    let nn: NeuralNet
    let structure: NeuralNet.Structure
    let winRanking: [Float] = [1,0,0]//[0.8,0.1,0.1]
    let looseRanking: [Float] = [0,0,1]//[0.1,0.1,0.8]
    let tieRanking: [Float] = [0,1,0]//[0.1,0.8,0.1]
    let c=Float(0.5) //Between 0 and 1, higher c -> faster learning
    let url = URL(fileURLWithPath: "/Users/Frej/Documents/Xcode/Projekt/Luffarschack/Luffarschack/TrainedAI")
    
    init(_ board: Board, _ xOrO: XorO){
        self.board=board
        self.xOrO=xOrO
        structure = try! NeuralNet.Structure(nodes: [board.side*board.side*2,128, 3],
                                                hiddenActivation: .rectifiedLinear, outputActivation: .softmax,
                                                batchSize: batchSize, learningRate: 0.1, momentum: 0.9)
        
        nn = try! NeuralNet(structure: structure)
        //nn = try! NeuralNet(url: url)
    }
    
    
    func nextMove()->Move {
        if(board.isEmpty){
            let n=0
            let interval=Array(n...board.side-1-n)
            return Move(row: interval.randomElement(),col: interval.randomElement(),xOrO: xOrO)
        }
        else{
            return bestMove(board.rankedBoard())
        }
    }
    
    /** Best moves for the player
     */
    func bestMove(_ rb: RankedBoard) -> Move {
        var bestMoves: [Move]=[]
        var m: Float = -Float.infinity
        //print("Good moves:")
        let gm=rb.goodMoves(for: xOrO, tol, limit)
        for move in gm{
            let copy=rb.copy()
            copy.put(move)
            let rank=ranking(copy.floatRankings(for: xOrO))
            //print(rank)
            let r=rank[0]-rank[2]
            if r>m{
                m=r
                bestMoves=[move]
            }
            else if r==m{
                bestMoves.append(move)
            }
        }
        let move=bestMoves.randomElement()
        let copy=rb.copy()
        copy.put(move)
        choices.append(Choice(data: copy.floatRankings(for: xOrO), ranking: ranking(copy.floatRankings(for: xOrO))))
        opponentsChoices.append(Choice(data: rb.floatRankings(for: opponent(xOrO)), ranking: ranking(rb.floatRankings(for: opponent(xOrO)))))
        return move
    }
    
    func ranking(_ data: [Float])-> [Float] {
        let d=Array(repeating: data, count: batchSize)
        return (try! nn.infer(d))[0]
    }
    
    func save(){
        try! nn.save(to: url)
    }
    
    func basicTraining()->Bool{
        let realBoard=board;
        var wins=0
        board = Board(side: Int(self.board.side))
        var players: [Player] = [MediumBot(board: board,xOrO: opponent(xOrO)), self]
        
        for n  in 1...10000 {
            //print("New Game!")
            loop: while(true){
                for player in players {
                    let move: Move
                    move=player.nextMove()
                    self.board.put(move)
                    //board.printBoard()
                    if let winner = board.win() {
                        if winner==xOrO {
                            print("win")
                            wins+=1
                            train(win: true)
                        }
                        else if winner==opponent(xOrO) {
                            print("loose")
                            train(win: false)
                            wins=0
                        }
                        else {
                            print("tie")
                            train(win: nil)
                            wins=0
                        }
                        board.clear()
                        players=players.reversed()
                        break loop
                    }
                }
            }
            if wins>10 {
                board=realBoard
                print(n)
                return true
            }
        }
        board=realBoard
        return false
    }
    
    func recursiveTraining(_ rb: RankedBoard, playersTurn: Bool)->Int{
        if let winner = rb.win(){
            switch(winner) {
            case xOrO:
                return 1
            case .empty:
                return 0
            default:
                return -1
            }
        } else if playersTurn {
            rb.put(bestMove(rb))
            return recursiveTraining(rb, playersTurn: false)
        } else {
            rb.put(rb.bestMoves(for: opponent(xOrO)).randomElement())
            return recursiveTraining(rb, playersTurn: true)
        }
    }
    
    func train(win: Bool?){
        var boards: [[Float]]=[]
        var newRankings: [[Float]]=[]
        var lastRanking: [Float]
        
        if data.count >= N {
            data.removeFirst()
            outputs.removeFirst()
        }
        
        if let w = win {
            if w {
                lastRanking=winRanking
            } else {
                lastRanking=looseRanking
            }
        } else {
            lastRanking=tieRanking
        }
        
        for choice in choices.reversed() {
            let newRanking=bayes(prior: choice.ranking, likelyhood: lastRanking)
            lastRanking=newRanking
            newRankings.append(newRanking)
            boards.append(choice.data)
        }
        
        if let w = win {
            if w {
                lastRanking=looseRanking
            } else {
                lastRanking=winRanking
            }
        } else {
            lastRanking=tieRanking
        }
        
        for choice in opponentsChoices.reversed() {
            let newRanking=bayes(prior: choice.ranking, likelyhood: lastRanking)
            lastRanking=newRanking
            newRankings.append(newRanking)
            boards.append(choice.data)
        }
        
        data.append(boards)
        outputs.append(newRankings)
        /*
        for _ in 1...1 {
            for (inputs, labels) in zip(data.joined(), outputs.joined()) {
                try! nn.infer(inputs)
                try! nn.backpropagate(labels)
            }
        }
 */
        
        var d=Array(data.joined())
        var o=Array(outputs.joined())
        let shuffled_indices = Array(d.indices).shuffled()
        
        d = shuffled_indices.map { d[$0] }
        o = shuffled_indices.map { o[$0] }
        
        while d.count>=batchSize {
            let batchData=Array(d.suffix(batchSize))
            d.removeLast(batchSize)
            let batchOutput=Array(o.suffix(batchSize))
            o.removeLast(batchSize)
            try! nn.infer(batchData)
            try! nn.backpropagate(batchOutput)
        }
        
        opponentsChoices.removeAll()
        choices.removeAll()
    }
    
    func bayes(prior: [Float], likelyhood: [Float])->[Float]{
        /*
         let res=[prior[0]*likelyhood[0],prior[1]*likelyhood[1],prior[2]*likelyhood[2]]
         let s=res.sum()
         return [res[0]/s,res[1]/s,res[2]/s]
         */
        let d=1-c
        return [d*prior[0]+c*likelyhood[0],d*prior[1]+c*likelyhood[1],d*prior[2]+c*likelyhood[2]] //Not bayes at all :(
    }
}

extension RankedBoard {
    func floatRankings(for player: XorO)->[Float]{
        var fr: [Float]=[]
        var rb: [[Int]]
        switch player {
        case .x:
            rb=rbX.rb
            rb.append(contentsOf: rbO.rb.reversed())
        case .o:
            rb=rbO.rb
            rb.append(contentsOf: rbX.rb.reversed())
        default:
            print("This is impossible!")
            return []
        }
        for row in rb {
            for ranking in row {
                fr.append(Float(ranking))
            }
        }
        //let m = fr.max()!
        let s = fr.sum()
        for i in 0..<fr.count {
            fr[i]=(fr[i]-s)/100000
        }

        return fr
    }
}




