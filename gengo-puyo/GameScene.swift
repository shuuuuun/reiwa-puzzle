//
//  GameScene.swift
//  gengo-puyo
//
//  Created by motoki-shun on 2019/04/03.
//  Copyright © 2019 motoki-shun. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {

    private var game: Puyo!
    private let gameUpdateInterval = 1.0
    private var lastUpdateTime: TimeInterval = 0.0

    private var baseStone: SKShapeNode?
    private var boardNodes: [SKShapeNode] = []
    private var currentBlockNodes: [SKShapeNode] = []

    private var stoneSize = CGFloat(90)
    private var boardHeight: CGFloat!

    private var touchBeginPos: CGPoint!
    private var touchLastPos: CGPoint!

    private var gameOverLabel: SKLabelNode?

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
        let gengoStoneList = charAry.enumerated().map { GengoStone(kind: $0.0, appearance: SKLabelNode(text: String($0.1)), char: $0.1) }
        self.game = Puyo(stoneList: gengoStoneList, stoneCountForClear: 2)

        // self.stoneSize = (self.size.width + self.size.height) * 0.05
        // print(stoneSize)
        self.boardHeight = self.stoneSize * CGFloat(self.game.rows)
        self.baseStone = SKShapeNode.init(rectOf: CGSize.init(width: stoneSize, height: stoneSize), cornerRadius: stoneSize * 0.35)
        if let stone = self.baseStone {
            stone.lineWidth = 2
            stone.strokeColor = UIColor(hex: "aaaaaa", alpha: 0.8)
        }

        self.gameOverLabel = self.childNode(withName: "//gameOverLabel") as? SKLabelNode
        if let label = self.gameOverLabel {
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
            if let label = self.gameOverLabel {
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
                if let n = self.baseStone?.copy() as! SKShapeNode? {
                    if stone != nil {
                        // n.strokeColor = stone!.appearance as! UIColor
                        // n.fillColor = stone!.appearance as! UIColor
                        let label = stone!.appearance as! SKNode
                        let newLabel = label.copy() as! SKNode
                        n.addChild(newLabel)
                    }
                    n.position = getBoardPosition(x: x, y: y)
                    self.boardNodes.append(n)
                    self.addChild(n)
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
                if stone == nil {
                    continue
                }
                // print(stone)
                let drawX = x + block.x
                let drawY = y + block.y - self.game.hiddenRows
                // print(drawX, drawY)
                if drawY < 0 {
                    continue
                }
                if let n = self.baseStone?.copy() as! SKShapeNode? {
                    // n.strokeColor = stone!.appearance as! UIColor
                    // n.fillColor = stone!.appearance as! UIColor
                    let label = stone!.appearance as! SKNode
                    let newLabel = label.copy() as! SKNode
                    n.addChild(newLabel)
                    n.position = getBoardPosition(x: drawX, y: drawY)
                    self.currentBlockNodes.append(n)
                    self.addChild(n)
                }
            }
        }
    }

    func getBoardPosition(x: Int, y: Int) -> CGPoint {
        let margin: CGFloat = 40
        let verticalMargin = self.size.height - self.boardHeight
        return CGPoint(
            x: self.stoneSize * CGFloat(x) - self.size.width/2 + self.stoneSize/2 + margin,
            y: -1 * (self.stoneSize * CGFloat(y) - self.size.height/2 + self.stoneSize/2 + verticalMargin - margin)
        )
    }
}
