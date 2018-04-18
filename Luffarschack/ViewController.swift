//
//  ViewController.swift
//  Luffarschack1
//
//  Created by Frej Berglind on 2017-06-13.
//  Copyright © 2017 Frej Berglind. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, LuffarGrafik {
    var collectionView: UICollectionView!
    var clicked = false
    var clickedCell: Cell!
    var undoIsClicked=false
    var newGameIsClicked=false
    var botIsThinking=false
    let side: CGFloat=11
    var board: UndoBoard!
    var players: [Player]=[]
    
    // Layout:
    let gap: CGFloat=3
    let inset: CGFloat=10
    let cellBackgroundColor=UIColor(white: 1, alpha: 1)
    let latestCellColor = UIColor(red: 0.75, green: 1, blue: 0.75, alpha: 1)
    var firstClick=true
    var label: UILabel!
    var lastCell: Cell?=nil
    var footer: UIToolbar!
    var undoButton: UIBarButtonItem!
    let defaultText="Click a cell to start playing!"
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpGraphics()
        DispatchQueue.global().async {
            self.setUpGame()
            self.playGame()
        }
    }
    
    /** Sets up the game when the app is started
     */
    func setUpGame(){
        board = UndoBoard(side: Int(side))
        players.append(Human(self, .x, board))
        //players.append(Human(self, .o, board))
        players.append(Beta(board: board, xOrO: .o))
        /*
        let AI=AIBot(board, .o)
        print("BasicTraining: \(AI.basicTraining())")
        AI.save()
        players.append(AI)
 */
    }
    
    /** Runs when the game is on!
     */
    func playGame(){
        while(true){
            for player in players {
                let move: Move
                if player is Human{
                    DispatchQueue.main.sync{
                        label.text="Your move!"
                    }
                    move=player.nextMove()
                    board.put(move)
                } else {
                    //botIsThinking=true
                    DispatchQueue.main.sync{
                        label.text="I am thinking..."
                    }
                    move=player.nextMove()
                    board.put(move)
                    //botIsThinking=false
                }
                
                DispatchQueue.main.sync{
                    putCellTo(move)
                    board.printBoard()
                }
                if let winner: XorO = board.win() {
                    gameOver(winner)
                }
            }
        }
    }
    
    /** Handles the end of the game
     */
    func gameOver(_ winner: XorO){
        DispatchQueue.main.sync{
            switch winner {
            case .x:
                print("X won!")
                label.text = "X won!"
            case .o:
                print("O won!")
                label.text = "O won!"
            default:
                print("It's a tie!")
                label.text = "It's a tie!"
            }
        }
        
        undoIsClicked=false
        newGameIsClicked=false
        while(!newGameIsClicked){
            usleep(10000) //10 millisekunder
            if(undoIsClicked){
                undoIsClicked=false
                return
            }
        }
        DispatchQueue.main.sync{
            label.text = defaultText
        }
    }
    
    /** Updates the board shown on the screen with move
     */
    func putCellTo(_ move: Move){
        let s=Int(side)
        let indexPath = IndexPath(item: move.row*s+move.col, section: 0)
        let cell = collectionView.cellForItem(at: indexPath) as! MyCollectionViewCell
        switch(move.xOrO){
        case .x: cell.myLabel.textColor = .red
        cell.myLabel.text = move.xOrO.description
        case .o: cell.myLabel.textColor = .blue
        cell.myLabel.text = move.xOrO.description
        default: cell.myLabel.text = ""
        }
        if let lc:Cell=lastCell{
            let lastCell = collectionView.cellForItem(at: IndexPath(item: lc.row*s+lc.col, section: 0)) as! MyCollectionViewCell
            lastCell.backgroundColor=cellBackgroundColor
        }
        cell.backgroundColor=latestCellColor
        lastCell=Cell(row: move.row, col: move.col)
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return Int(side*side)
        
    }
    
    // Properties of the cells.
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let screenSize = UIScreen.main.bounds
        let screenWidth = CGFloat(screenSize.width)
        let cellSize = (screenWidth-20)/side-gap
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath as IndexPath) as! MyCollectionViewCell
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 2*cellSize, height: 2*cellSize))
        label.center = CGPoint(x: cellSize/2, y: 0.37*cellSize)
        label.textAlignment = .center
        label.font=UIFont.systemFont(ofSize: 1.5*cellSize)
        cell.myLabel=label
        cell.backgroundColor = cellBackgroundColor
        cell.addSubview(cell.myLabel)
        return cell
        
    }
    
    // This is run if a cell is clicked
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let s=Int(side)
        clickedCell=Cell(row: indexPath.item/s, col: indexPath.item%s)
        clicked=true
    }
    
    /** Sets up the graphics for the game.
     */
    func setUpGraphics(){
        let screenSize = UIScreen.main.bounds
        let screenWidth = CGFloat(screenSize.width)
        let screenHeight = CGFloat(screenSize.height)
        
        
        //The board:
        let layout = UICollectionViewFlowLayout()
        
        layout.sectionInset = UIEdgeInsets(top: 60, left: inset, bottom: inset, right: inset)
        
        layout.itemSize = CGSize(width: Int((screenWidth-20)/side-gap), height: Int((screenWidth-20)/side-gap))
        
        layout.minimumInteritemSpacing = gap
        layout.minimumLineSpacing = gap
        
        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        
        collectionView.dataSource = self
        
        collectionView.delegate = self
        
        collectionView.register(MyCollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        
        collectionView.backgroundColor = UIColor.black
        
        self.view.addSubview(collectionView)
        
        //Header:
        let header = UIToolbar(frame: CGRect(x: 0, y: 20, width: screenWidth, height: 40))
        header.barTintColor = .black
        
        let player1Button = UIBarButtonItem(
            title: "Player x",
            style: .plain,
            target: self,
            action: #selector(choosePlayer1)
        )
        
        player1Button.tintColor = .white
        
        let player2Button = UIBarButtonItem(
            title: "Player o",
            style: .plain,
            target: self,
            action: #selector(choosePlayer2)
        )
        
        player2Button.tintColor = .white
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)
        
        header.setItems([player1Button, flexibleSpace, player2Button], animated: false)
        header.contentMode = .center
        self.view.addSubview(header)
        
        
        //Message for players:
        label=UILabel(frame: CGRect(x: 0, y: screenHeight-80, width: screenWidth, height: 40))
        label.text=defaultText
        label.textAlignment = .center
        label.textColor = UIColor(white: 1, alpha: 1)
        self.view.addSubview(label)
        
        //Footer:
        
        footer = UIToolbar(frame: CGRect(x: 0, y: screenHeight-40, width: screenWidth, height: 40))
        footer.barTintColor=UIColor(white: 0, alpha: 1)
        
        undoButton = UIBarButtonItem(
            title: "Undo",
            style: .plain,
            target: self,
            action: #selector(undo)
        )
        
        undoButton.tintColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        
        
        let newGameButton = UIBarButtonItem(
            title: "New Game",
            style: .plain,
            target: self,
            action: #selector(newGame)
        )
        
        newGameButton.tintColor = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
        
        footer.setItems([undoButton, flexibleSpace, newGameButton], animated: false)
        footer.contentMode = .center
        self.view.addSubview(footer)
    }
    
    /** Player picker for x
     */
    @objc func choosePlayer1(_ sender: UIButton){
        DispatchQueue.global().sync {
            pickPlayer(.x, 0)
        }
    }
    
    /** Player picker for o
     */
    @objc func choosePlayer2(){
        pickPlayer(.o, 1)
    }
    
    /** Retrieves the data from PickerDialog
     */
    func pickPlayer(_ xOrO: XorO, _ n: Int){
        let pickerData = [
            ["value": "Human", "display": "Human"],
            ["value": "EasyBot", "display": "Easy Bot"],
            ["value": "MediumBot", "display": "Medium Bot"],
            ["value": "MasterBot", "display": "Master Bot"],
            //["value": "WittyBot", "display": "Witty Bot"],
            ["value": "Alpha", "display": "Alpha"],
            ["value": "Beta", "display": "Beta"],
            ["value": "Gamma", "display": "Gamma"]
        ]
        
        PickerDialog().show("Choose player", options: pickerData, selected: String(describing: players[n])) {
            (value) -> Void in
            switch(value){
            case "Human": self.players[n] = Human(self, xOrO, self.board)
            case "EasyBot": self.players[n] = EasyBot(board: self.board, xOrO: xOrO)
            case "MediumBot": self.players[n] = MediumBot(board: self.board, xOrO: xOrO)
            case "MasterBot": self.players[n] = MasterBot(board: self.board, xOrO: xOrO)
            //case "WittyBot": self.players[n] =  MediumBot(board: self.board, xOrO: xOrO)
            case "Alpha":self.players[n] = Alpha(board: self.board, xOrO: xOrO)
            case "Beta":self.players[n] = Beta(board: self.board, xOrO: xOrO)
            case "Gamma":self.players[n] = Gamma(board: self.board, xOrO: xOrO)
            default: fatalError("This ain't good!")
            }
            print(value)
        }
        
    }
    
    /** Undos 1 move if there are two human players, otherwise 2 moves.
     */
    @objc func undo(){
        undoIsClicked=true
        var nbrOfHumanPlayers=0
        for player in players{
            if player is Human{
                nbrOfHumanPlayers+=1
            }
        }
        
        
        if let move: Move = board.undo(){
            putCellTo(Move(row: move.row, col: move.col, xOrO: .empty))
        }
        
        while botIsThinking {
            usleep(100000) //100 millisekunder
        }
        
        if nbrOfHumanPlayers==1 {
            if let move: Move = board.undo(){
                putCellTo(Move(row: move.row, col: move.col, xOrO: .empty))
            }
        }
    }
    
    /** Sets up a new game
     */
    @objc func newGame(){
        board.clear()
        clearAllCells()
        newGameIsClicked=true
        clicked=false
        label.text = defaultText
    }
    
    /** Clears the board shown on screen.
     */
    func clearAllCells() {
        for row in 0..<Int(side) {
            for col in 0..<Int(side) {
                putCellTo(Move(row: row, col: col, xOrO: .empty))
            }
        }
        print("New Game!")
        
        if let lc:Cell=lastCell{
            let s=Int(side)
            let lastCell = collectionView.cellForItem(at: IndexPath(item: lc.row*s+lc.col, section: 0)) as! MyCollectionViewCell
            lastCell.backgroundColor=cellBackgroundColor
        }
        lastCell=nil
    }
    
    //Statusbar:
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /** Retrives clicked cell
     */
    func getClickedCell() -> Cell? {
        clicked=false
        let cell=clickedCell
        clickedCell=nil
        return cell
    }
    
    /** True if cell any cell is clicked
     */
    func isClicked() -> Bool {
        return clicked
    }
}

/** Protocol recuired to support Human players
 */
protocol LuffarGrafik {
    
    func isClicked() ->Bool
    
    func getClickedCell() ->Cell?
}

/** Human player
 */
struct Human: Player {
    let grafik: LuffarGrafik
    let xOrO: XorO
    let board: Board
    let description = "Human"
    
    init(_ grafik: LuffarGrafik, _ xOrO: XorO, _ board: Board){
        self.grafik=grafik
        self.xOrO=xOrO
        self.board=board
    }
    func nextMove() -> Move {
        while(!self.grafik.isClicked()){
            usleep(10000) //10 millisekunder
        }
        let cell=grafik.getClickedCell()!
        if self.board.get(cell) == .empty{
            return Move(cell, xOrO)
        } else {
            return nextMove()
        }
    }
}

class MyCollectionViewCell: UICollectionViewCell {
    var myLabel = UILabel()
}

