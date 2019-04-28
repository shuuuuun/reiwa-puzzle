//
//  GameScene.swift
//  gengo-puyo
//
//  Created by motoki-shun on 2019/04/03.
//  Copyright © 2019 motoki-shun. All rights reserved.
//

import SpriteKit
import GameplayKit
import PromiseKit

class GameScene: SKScene {

    private var game: Puyo!
    private let gameUpdateInterval = 1.0
    private var lastUpdateTime: TimeInterval = 0.0

    private var baseStone: SKShapeNode?
    private var boardNodes: [SKShapeNode] = []
    private var currentBlockNodes: [SKShapeNode] = []

    private var stoneSize = CGFloat(90)
    private var boardWidth: CGFloat!
    private var boardHeight: CGFloat!
    private let boardMargin: CGFloat = 40

    private var touchBeginPos: CGPoint!
    private var touchLastPos: CGPoint!

    private var notificationLabel: SKLabelNode?

    override func didMove(to view: SKView) {
        // let colorList = [
        //     UIColor(hex: "FF6666", alpha: 0.8),
        //     UIColor(hex: "FFCC66", alpha: 0.8),
        //     UIColor(hex: "FFFF66", alpha: 0.8),
        //     UIColor(hex: "CCFF66", alpha: 0.8),
        //     UIColor(hex: "66FF66", alpha: 0.8),
        //     UIColor(hex: "66FFCC", alpha: 0.8),
        //     UIColor(hex: "66FFFF", alpha: 0.8),
        //     UIColor(hex: "66CCFF", alpha: 0.8),
        // ]
        // self.game = Puyo(stoneList: colorList.enumerated().map { ColorStone(kind: $0.0, appearance: $0.1) })

        let charAry = GengoStone.gengoList.map { Array($0) }.flatMap { $0 }
        print(charAry)
        // let labelAry = charAry.map { SKLabelNode(text: String($0)) }
        // let gengoStoneList = labelAry.enumerated().map { GengoStone(kind: $0.0, appearance: $0.1) }
        // let gengoStoneList = charAry.enumerated().map { GengoStone(kind: $0.0, appearance: SKLabelNode(text: String($0.1)), char: $0.1) }
        let gengoStoneList = charAry.enumerated().map { (index, char) -> GengoStone in
            let label = SKLabelNode(text: String(char))
            // label.fontName = "YuMincho Medium"
            label.fontName = "Hiragino Mincho ProN"
            label.fontSize = 70
            label.position = CGPoint(x: 0, y: -25)
            label.color = UIColor(hex: "cccccc")
            return GengoStone(kind: index, appearance: label, char: char)
        }
        self.game = Puyo(stoneList: gengoStoneList, stoneCountForClear: 2)
        self.game.clearEffect = { stones in
            print("clearEffect")
            let (promise, resolver) = Promise<Void>.pending()
            var text: String = ""
            for stone in stones {
                let label = stone.appearance as! SKLabelNode
                label.color = UIColor(hex: "ffcc66")
                if let gengoStone = stone as? GengoStone {
                    text += String(gengoStone.char)
                }
            }
            if let label = self.notificationLabel {
                let fadeIn  = SKAction.fadeIn(withDuration: 0.5)
                let delay   = SKAction.wait(forDuration: TimeInterval(0.8))
                let fadeOut = SKAction.fadeOut(withDuration: 0.5)
                let finally = SKAction.run({ resolver.fulfill(Void()) })
                label.alpha = 0.0
                label.text = text
                label.run(SKAction.sequence([fadeIn, delay, fadeOut, finally]))
            }
            return promise
        }

        // self.stoneSize = (self.size.width + self.size.height) * 0.05
        // print(stoneSize)
        self.boardWidth = self.stoneSize * CGFloat(self.game.cols)
        self.boardHeight = self.stoneSize * CGFloat(self.game.rows)

        let boardFrame = SKShapeNode(rectOf: CGSize(width: self.boardWidth, height: self.boardHeight), cornerRadius: 10)
        boardFrame.lineWidth = 2
        boardFrame.strokeColor = UIColor(hex: "cccccc")
        boardFrame.position = CGPoint(x: -(self.size.width - self.boardWidth)/2 + self.boardMargin, y: -(self.size.height - self.boardHeight)/2 + self.boardMargin)
        self.addChild(boardFrame)

        // self.baseStone = SKShapeNode.init(rectOf: CGSize.init(width: stoneSize, height: stoneSize), cornerRadius: stoneSize * 0.35)
        let stone = SKShapeNode(rectOf: CGSize(width: stoneSize, height: stoneSize))
        stone.lineWidth = 1
        stone.strokeColor = UIColor(hex: "cccccc", alpha: 0.2)
        // stone.strokeColor = UIColor(hex: "111111", alpha: 0.5)
        self.baseStone = stone

        self.notificationLabel = self.childNode(withName: "//notificationLabel") as? SKLabelNode
        if let label = self.notificationLabel {
            label.alpha = 0.0
        }

        // start game
        self.game.newGame()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesBegan")
        // for t in touches { self.touchDown(atPoint: t.location(in: self)) }
        if self.touchBeginPos != nil {
            return
        }
        let touch = touches.first!
        self.touchBeginPos = touch.location(in: self)
        self.touchLastPos = self.touchBeginPos
        print(self.touchBeginPos)
        // TODO: 2本指対応
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // print("touchesMoved")
        // for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
        if self.touchBeginPos == nil {
            return
        }
        let touch = touches.first!
        let movedPos = touch.location(in: self)
        let diffX = movedPos.x - self.touchLastPos.x
        let diffY = movedPos.y - self.touchLastPos.y
        if diffX > 100 {
            print("moveBlockRight", diffX)
            _ = self.game.moveBlockRight()
            self.touchLastPos = movedPos
        }
        else if diffX < -100 {
            print("moveBlockLeft", diffX)
            _ = self.game.moveBlockLeft()
            self.touchLastPos = movedPos
        }
        else if diffY < -100 {
            print("moveBlockDown", diffY)
            _ = self.game.moveBlockDown()
            self.touchLastPos = movedPos
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesEnded")
        // for t in touches { self.touchUp(atPoint: t.location(in: self)) }
        if self.touchBeginPos != nil {
            let touch = touches.first!
            let movedPos = touch.location(in: self)
            let diffX = movedPos.x - self.touchBeginPos.x
            let diffY = movedPos.y - self.touchBeginPos.y
            let diff = sqrtf(Float(diffX*diffX + diffY*diffY))
            // print(diff)
            if diff < 100 {
                print("tapped", diff)
                _ = self.game.rotateBlock()
            }
        }
        self.touchBeginPos = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesCancelled")
        // for t in touches { self.touchUp(atPoint: t.location(in: self)) }
        self.touchBeginPos = nil
    }

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        // print(currentTime)

        if !self.game.isPlayng {
            if let label = self.notificationLabel {
                label.text = "ゲームオーバー"
                label.alpha = 0.0
                label.run(SKAction.fadeIn(withDuration: 0.5))
            }
            return
        }
        if lastUpdateTime + gameUpdateInterval <= currentTime {
            self.game.update()
            // print(self.game.board)
            lastUpdateTime = currentTime
        }
        draw()
    }

    func draw() {
        drawBoard()
        drawCurrentBlock()
    }

    func drawBoard() {
        self.removeChildren(in: self.boardNodes)
        self.boardNodes.removeAll()
        for (y, row) in self.game.board.enumerated() {
            for (x, stone) in row.enumerated() {
                if let newNode = self.drawStone(stone: stone, x: x, y: y) {
                    self.boardNodes.append(newNode)
                }
            }
        }
    }

    func drawCurrentBlock() {
        self.removeChildren(in: self.currentBlockNodes)
        self.currentBlockNodes.removeAll()
        let block = self.game.currentBlock!
        for (y, row) in block.shape.enumerated() {
            for (x, stone) in row.enumerated() {
                guard let boardStone = stone else {
                    continue
                }
                let drawX = x + block.x
                let drawY = y + block.y - self.game.hiddenRows
                if drawY < 0 {
                    continue
                }
                if let newNode = self.drawStone(stone: boardStone, x: drawX, y: drawY) {
                    newNode.lineWidth = 0
                    self.currentBlockNodes.append(newNode)
                }
            }
        }
    }

    func drawStone(stone: Stone?, x: Int, y: Int) -> SKShapeNode? {
        guard let newStoneNode = self.baseStone?.copy() as! SKShapeNode? else {
            return nil
        }
        if let unwrappedStone = stone {
            // newStoneNode.strokeColor = unwrappedStone.appearance as! UIColor
            // newStoneNode.fillColor = unwrappedStone.appearance as! UIColor
            let label = unwrappedStone.appearance as! SKNode
            let newLabel = label.copy() as! SKNode
            newStoneNode.addChild(newLabel)
        }
        newStoneNode.position = getBoardPosition(x: x, y: y)
        self.addChild(newStoneNode)
        return newStoneNode
    }

    func getBoardPosition(x: Int, y: Int) -> CGPoint {
        let verticalMargin = self.size.height - self.boardHeight
        return CGPoint(
            x: self.stoneSize * CGFloat(x) - self.size.width/2 + self.stoneSize/2 + self.boardMargin,
            y: -1 * (self.stoneSize * CGFloat(y) - self.size.height/2 + self.stoneSize/2 + verticalMargin - self.boardMargin)
        )
    }
}
