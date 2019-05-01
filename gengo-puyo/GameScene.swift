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

enum AppError: Error {
    case common
}

class GameScene: SKScene {

    private var game: Puyo!
    private let gameUpdateInterval = 1.0
    private var lastUpdateTime: TimeInterval = 0.0

    private let mainNode: SKEffectNode = SKEffectNode()
    private let notificationNode = SKNode()
    private var notificationTapAction = SKAction()
    private var baseStone: SKShapeNode?
    private var boardNodes: [SKShapeNode] = []
    private var currentBlockNodes: [SKShapeNode] = []

    private var stoneSize = CGFloat(90)
    private var boardWidth: CGFloat!
    private var boardHeight: CGFloat!
    private let boardMargin: CGFloat = 40

    private let touchThreshold: CGFloat = 100
    private var touchBeginPos: CGPoint!
    private var touchLastPos: CGPoint!

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
        // charAry.insert("令和", at: 0)
        // charAry.append(contentsOf: Array("令和"))
        // let labelAry = charAry.map { SKLabelNode(text: String($0)) }
        // let gengoStoneList = labelAry.enumerated().map { GengoStone(kind: $0.0, appearance: $0.1) }
        // let gengoStoneList = charAry.enumerated().map { GengoStone(kind: $0.0, appearance: SKLabelNode(text: String($0.1)), char: $0.1) }
        let gengoStoneList = charAry.enumerated().map { (index, char) -> GengoStone in
            let label = SKLabelNode(text: String(char))
            // label.fontName = "YuMincho Medium"
            label.fontName = "Hiragino Mincho ProN"
            label.fontSize = 70
            label.position = CGPoint(x: 0, y: -25)
            label.fontColor = UIColor(hex: "eeeeee")
            return GengoStone(kind: index, appearance: label, char: char)
        }
        self.game = Puyo(stoneList: gengoStoneList, stoneCountForClear: 2)
        self.game.clearEffect = self.clearEffect

        self.boardWidth = self.stoneSize * CGFloat(self.game.cols)
        self.boardHeight = self.stoneSize * CGFloat(self.game.rows)

        let boardFrame = SKShapeNode(rectOf: CGSize(width: self.boardWidth, height: self.boardHeight), cornerRadius: 10)
        boardFrame.lineWidth = 2
        boardFrame.strokeColor = UIColor(hex: "cccccc")
        boardFrame.position = CGPoint(x: -(self.size.width - self.boardWidth)/2 + self.boardMargin, y: -(self.size.height - self.boardHeight)/2 + self.boardMargin)
        self.mainNode.addChild(boardFrame)

        // self.baseStone = SKShapeNode.init(rectOf: CGSize.init(width: stoneSize, height: stoneSize), cornerRadius: stoneSize * 0.35)
        let stone = SKShapeNode(rectOf: CGSize(width: stoneSize, height: stoneSize))
        stone.lineWidth = 1
        stone.strokeColor = UIColor(hex: "cccccc", alpha: 0.2)
        // stone.strokeColor = UIColor(hex: "111111", alpha: 0.5)
        self.baseStone = stone

        if let titleLabel = self.childNode(withName: "//titleLabel") as? SKLabelNode {
            titleLabel.move(toParent: self.mainNode)
        }

        // self.notificationNode.name = "notification"
        // self.notificationNode.frame = self.frame
        self.notificationNode.isHidden = true
        // self.notificationNode.isUserInteractionEnabled = true
        self.addChild(self.notificationNode)

        self.mainNode.filter = CIFilter(name: "CIGaussianBlur")!
        self.mainNode.blendMode = .alpha
        self.mainNode.shouldEnableEffects = false
        self.addChild(self.mainNode)

        // start game
        self.game.newGame()

        // 最初ぜったい令和
        let reiwa = [gengoStoneList.last { $0.char == "令" }!, gengoStoneList.last { $0.char == "和" }!]
        self.game.currentBlock = Block(stones: reiwa, x: 3, y: -2)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // print("touchesBegan")
        // for t in touches { self.touchDown(atPoint: t.location(in: self)) }
        if self.touchBeginPos != nil {
            return
        }
        let touch = touches.first!
        self.touchBeginPos = touch.location(in: self)
        self.touchLastPos = self.touchBeginPos
        // print(self.touchBeginPos)
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
        if diffX > self.touchThreshold {
            print("moveBlockRight", diffX)
            _ = self.game.moveBlockRight()
            self.touchLastPos = movedPos
        }
        else if diffX < -self.touchThreshold {
            print("moveBlockLeft", diffX)
            _ = self.game.moveBlockLeft()
            self.touchLastPos = movedPos
        }
        else if diffY < -self.touchThreshold {
            print("moveBlockDown", diffY)
            _ = self.game.moveBlockDown()
            self.touchLastPos = movedPos
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // print("touchesEnded")
        // for t in touches { self.touchUp(atPoint: t.location(in: self)) }
        if self.touchBeginPos != nil {
            let touch = touches.first!
            let movedPos = touch.location(in: self)
            let diffX = movedPos.x - self.touchBeginPos.x
            let diffY = movedPos.y - self.touchBeginPos.y
            let diff = CGFloat(sqrtf(Float(diffX*diffX + diffY*diffY)))
            if diff < self.touchThreshold {
                let touchedNode = self.atPoint(movedPos)
                print("tapped", diff, touchedNode.name)
                // if touchedNode.name == self.notificationNode.name {
                if !self.notificationNode.isHidden {
                    self.notificationNode.run(self.notificationTapAction)
                }
                else {
                    _ = self.game.rotateBlock()
                }
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
            _ = self.showNotification(title: "終了", description: "開始↻", tapAction: {
                self.game.restartGame()
                self.hideNotification()
            })
            return
        }
        if lastUpdateTime + gameUpdateInterval <= currentTime {
            self.game.update()
            lastUpdateTime = currentTime
        }
        draw()
    }

    private func showNotification(title: String, description: String? = nil, tapAction: @escaping () -> Void = {}) -> Promise<Void> {
        let (promise, resolver) = Promise<Void>.pending()

        if !self.notificationNode.isHidden {
            print("notificationNode is already shown.")
            resolver.reject(AppError.common)
            return promise
        }

        let titleLabel = SKLabelNode(text: title)
        // titleLabel.name = "notification"
        titleLabel.fontName = "Hiragino Mincho ProN"
        titleLabel.fontSize = 110
        titleLabel.fontColor = UIColor(hex: "eeeeee")
        self.notificationNode.addChild(titleLabel)

        if let description = description {
            for (index, desc) in description.split(separator: "\n").enumerated() {
                let label = SKLabelNode(text: String(desc))
                label.fontName = "Hiragino Mincho ProN"
                label.fontSize = 45
                label.fontColor = UIColor(hex: "eeeeee")
                label.position = CGPoint(x: 0, y: titleLabel.position.y - 120 - 65 * CGFloat(index))
                self.notificationNode.addChild(label)
            }
        }
        self.notificationTapAction = SKAction.run(tapAction)

        let fadeIn  = SKAction.fadeIn(withDuration: 0.5)
        let delay   = SKAction.wait(forDuration: TimeInterval(1.0))
        let finally = SKAction.run({
            resolver.fulfill(Void())
        })
        self.mainNode.shouldEnableEffects = true
        self.notificationNode.isHidden = false
        self.notificationNode.alpha = 0.0
        self.notificationNode.run(SKAction.sequence([fadeIn, delay, finally]))

        return promise
    }

    private func hideNotification() -> Promise<Void> {
        let (promise, resolver) = Promise<Void>.pending()

        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let finally = SKAction.run({
            self.mainNode.shouldEnableEffects = false
            self.notificationNode.removeAllChildren()
            self.notificationNode.isHidden = true
            resolver.fulfill(Void())
        })
        self.notificationNode.run(SKAction.sequence([fadeOut, finally]))

        return promise
    }

    private func clearEffect(pair: StonePair) -> Promise<Void> {
        print("clearEffect")
        let (promise, resolver) = Promise<Void>.pending()
        var effectNodes: [SKShapeNode] = []
        var gengoText: String = ""
        let draw: (Stone, Point) -> Void = { (stone, point) -> Void in
            guard let gengoStone = stone as? GengoStone else {
                return
            }
            let newStone = gengoStone.copy()
            newStone.label.fontColor = UIColor(hex: "FF6666")
            if let newNode = self.drawStone(stone: newStone, x: point.x, y: point.y) {
                newNode.zPosition = 1
                effectNodes.append(newNode)
            }
            gengoText += String(gengoStone.char)
        }
        draw(pair.leftStone, pair.leftPoint)
        draw(pair.rightStone, pair.rightPoint)
        let gengoData = GengoStone.gengoData.first { $0.name == gengoText }
        _ = firstly {
            self.showNotification(title: gengoText, description: gengoData?.description)
        }.then {
            self.hideNotification()
        }.ensure {
            self.mainNode.removeChildren(in: effectNodes)
            resolver.fulfill(Void())
        }
        return promise
    }

    private func draw() {
        drawBoard()
        drawCurrentBlock()
    }

    private func drawBoard() {
        self.mainNode.removeChildren(in: self.boardNodes)
        self.boardNodes.removeAll()
        for (y, row) in self.game.board.enumerated() {
            for (x, stone) in row.enumerated() {
                if let newNode = self.drawStone(stone: stone, x: x, y: y) {
                    self.boardNodes.append(newNode)
                }
            }
        }
    }

    private func drawCurrentBlock() {
        self.mainNode.removeChildren(in: self.currentBlockNodes)
        self.currentBlockNodes.removeAll()
        guard let block = self.game.currentBlock else {
            return
        }
        for (y, row) in block.shape.enumerated() {
            for (x, stone) in row.enumerated() {
                guard let boardStone = stone else {
                    continue
                }
                let drawX = x + block.x
                let drawY = y + block.y
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

    private func drawStone(stone: Stone?, x: Int, y: Int) -> SKShapeNode? {
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
        self.mainNode.addChild(newStoneNode)
        return newStoneNode
    }

    private func getBoardPosition(x: Int, y: Int) -> CGPoint {
        let verticalMargin = self.size.height - self.boardHeight
        return CGPoint(
            x: self.stoneSize * CGFloat(x) - self.size.width/2 + self.stoneSize/2 + self.boardMargin,
            y: -1 * (self.stoneSize * CGFloat(y) - self.size.height/2 + self.stoneSize/2 + verticalMargin - self.boardMargin)
        )
    }
}
