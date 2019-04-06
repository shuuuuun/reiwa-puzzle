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

    private let game = Puyo(colorList: [SKColor.red, SKColor.blue, SKColor.green, SKColor.yellow])
    private let gameUpdateInterval = 1.0
    private var lastUpdateTime: TimeInterval = 0.0

    private var baseStone: SKShapeNode?
    private var boardNodes: [SKShapeNode] = []
    private var currentBlockNodes: [SKShapeNode] = []

    private var stoneSize = CGFloat(100)

    private var touchBeginPos: CGPoint!
    private var touchLastPos: CGPoint!

    override func didMove(to view: SKView) {
        self.stoneSize = (self.size.width + self.size.height) * 0.05
        print(stoneSize)
        self.baseStone = SKShapeNode.init(rectOf: CGSize.init(width: stoneSize, height: stoneSize), cornerRadius: stoneSize * 0.3)
        if let stone = self.baseStone {
            stone.lineWidth = 2
            stone.strokeColor = SKColor.gray
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
                        n.strokeColor = stone!.color as! UIColor
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
                    n.strokeColor = stone!.color as! UIColor
                    n.position = getBoardPosition(x: drawX, y: drawY)
                    self.currentBlockNodes.append(n)
                    self.addChild(n)
                }
            }
        }
    }

    func getBoardPosition(x: Int, y: Int) -> CGPoint {
        return CGPoint(
            x: self.stoneSize * CGFloat(x) - self.size.width/2 + self.stoneSize,
            y: -1 * (self.stoneSize * CGFloat(y) - self.size.height/2 + self.stoneSize)
        )
    }
}
