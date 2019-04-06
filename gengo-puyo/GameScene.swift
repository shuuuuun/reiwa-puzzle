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

    override func didMove(to view: SKView) {
        self.stoneSize = (self.size.width + self.size.height) * 0.05
        print(stoneSize)
        self.baseStone = SKShapeNode.init(rectOf: CGSize.init(width: stoneSize, height: stoneSize), cornerRadius: stoneSize * 0.3)
        if let stone = self.baseStone {
            stone.lineWidth = 2
            stone.strokeColor = SKColor.gray
        }
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
    }
    
    func touchMoved(toPoint pos : CGPoint) {
    }
    
    func touchUp(atPoint pos : CGPoint) {
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // if let label = self.label {
        //     label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
        // }
        
        // for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        // print(currentTime)

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
                    n.position = CGPoint(x: stoneSize * CGFloat(x) - self.size.width/2 + stoneSize, y: stoneSize * CGFloat(y) - self.size.height/2 + stoneSize)
                    self.boardNodes.append(n)
                    self.addChild(n)
                }
            }
        }
    }

    func drawCurrentBlock() {
        self.removeChildren(in: self.currentBlockNodes)
        self.currentBlockNodes.removeAll()
        let block = self.game.currentBlock
        for (y, row) in block.shape.enumerated() {
            for (x, stone) in row.enumerated() {
                if stone == nil {
                    continue
                }
                print(stone)
                let drawX = x + block.x
                let drawY = y + block.y - self.game.hidden_rows
                print(drawX, drawY)
                if drawY < 0 {
                    continue
                }
                if let n = self.baseStone?.copy() as! SKShapeNode? {
                    n.strokeColor = stone!.color as! UIColor
                    // n.strokeColor = SKColor.red
                    n.position = CGPoint(x: stoneSize * CGFloat(drawX) - self.size.width/2 + stoneSize, y: stoneSize * CGFloat(drawY) - self.size.height/2 + stoneSize)
                    self.currentBlockNodes.append(n)
                    self.addChild(n)
                }
            }
        }
    }
}
