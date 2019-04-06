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

    let game = Puyo()
    let gameUpdateInterval = 1.0
    var lastUpdateTime: TimeInterval = 0.0

    private var baseStone: SKShapeNode?

    override func didMove(to view: SKView) {
        let w = (self.size.width + self.size.height) * 0.05
        self.baseStone = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
                if let stone = self.baseStone {
            stone.lineWidth = 2.5
            stone.strokeColor = SKColor.green
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
        let w = (self.size.width + self.size.height) * 0.05
        for (y, row) in self.game.board.enumerated() {
            for (x, _) in row.enumerated() {
                if let n = self.baseStone?.copy() as! SKShapeNode? {
                    n.position = CGPoint(x: w * CGFloat(x) - self.size.width/2 + w, y: w * CGFloat(y) - self.size.height/2 + w)
                    self.addChild(n)
                }
            }
        }
    }

    func drawCurrentBlock() {
    }
}
