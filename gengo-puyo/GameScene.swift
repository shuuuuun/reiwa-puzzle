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
import FirebaseAnalytics
import FirebaseAuth
import FirebaseFirestore

enum AppError: Error {
    case common
}

class GameScene: SKScene, UITextFieldDelegate {

    private var game: Puyo!
    private let gameUpdateInterval = 1.0
    private var lastUpdateTime: TimeInterval = 0.0
    private var reiwaBlock: Block?

    private let mainNode: SKEffectNode = SKEffectNode()
    private let modalNode = SKNode()
    private var modalTapAction = SKAction()
    private var scoreNumLabel: SKLabelNode!
    private var menuNode: SKNode!
    private var boardNodes: [SKShapeNode] = []
    private var currentBlockNodes: [SKShapeNode] = []
    private var nextBlockNodes: [SKShapeNode] = []
    private var nextNode = SKNode()

    private var stoneSize = CGFloat(90)
    private var boardWidth: CGFloat!
    private var boardHeight: CGFloat!
    private let boardMargin: CGFloat = 40

    private let touchThreshold: CGFloat = 100
    private var touchBeginPos: CGPoint!
    private var touchLastPos: CGPoint!

    private var tapActions: [String: () -> Void] = [:]
    private var textFieldActions: [UITextField: (String) -> Void] = [:]

    private let db = Firestore.firestore()
    private var user: User?

    private let numKanji = Array("一二三四五六七八九十")

    override func sceneDidLoad() {
        print("sceneDidLoad")
        Auth.auth().signInAnonymously() { (authResult, error) in
            self.user = authResult?.user
            self.sendUserData()
        }
    }

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

        var charAry = GengoStone.gengoList.map { Array($0) }.flatMap { $0 }
        // 令和と平成は出やすくする
        charAry += Array(repeating: Array("平成"), count: 10).flatMap { $0 }
        charAry += Array(repeating: Array("令和"), count: 100).flatMap { $0 }
        let gengoStoneList = charAry.enumerated().map { (index, char) -> GengoStone in
            let label = self.makeDefaultLabel(text: String(char), fontSize: 70, yPosition: -25)
            return GengoStone(kind: index, appearance: label, char: char)
        }
        let reiwa = [gengoStoneList.last { $0.char == "令" }!, gengoStoneList.last { $0.char == "和" }!]
        self.reiwaBlock = Block(stones: reiwa, x: 3, y: 0)
        self.game = Puyo(stoneList: gengoStoneList, stoneCountForClear: 2)
        self.game.clearEffect = self.clearEffect
        self.game.calcScore = self.calcScore

        self.boardWidth = self.stoneSize * CGFloat(self.game.cols)
        self.boardHeight = self.stoneSize * CGFloat(self.game.rows)

        let boardFrame = SKShapeNode(rectOf: CGSize(width: self.boardWidth, height: self.boardHeight), cornerRadius: 10)
        boardFrame.lineWidth = 2
        boardFrame.strokeColor = UIColor(hex: "cccccc")
        boardFrame.position = CGPoint(x: -(self.size.width - self.boardWidth)/2 + self.boardMargin, y: -(self.size.height - self.boardHeight)/2 + self.boardMargin)
        self.mainNode.addChild(boardFrame)

        let nextFrame = SKShapeNode(rectOf: CGSize(width: self.stoneSize, height: self.stoneSize * 2), cornerRadius: 10)
        nextFrame.lineWidth = 2
        nextFrame.strokeColor = UIColor(hex: "cccccc")
        self.nextNode.position = CGPoint(x: self.size.width/2 - 85, y: 292)
        self.nextNode.addChild(nextFrame)
        self.mainNode.addChild(self.nextNode)

        if let main = self.childNode(withName: "//main") {
            main.move(toParent: self.mainNode)
            self.scoreNumLabel = main.childNode(withName: "//scoreNum") as? SKLabelNode
            self.menuNode = main.childNode(withName: "//menu")
        }

        self.modalNode.name = "modal"
        self.modalNode.isHidden = true
        self.addChild(self.modalNode)

        self.mainNode.filter = CIFilter(name: "CIGaussianBlur")!
        self.mainNode.blendMode = .alpha
        self.mainNode.shouldEnableEffects = false
        self.addChild(self.mainNode)

        self.game.onGameOver = {
            Analytics.logEvent("gameover", parameters: [
                "score": self.game.score
            ])
            if self.game.score > self.getHighScore() {
                self.setHighScore(score: self.game.score)
            }
            self.setLastScore(score: self.game.score)
            self.sendUserData()
        }

        self.startGame()

        self.showAbout()
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
            self.game.moveBlockRight()
            self.touchLastPos = movedPos
        }
        else if diffX < -self.touchThreshold {
            print("moveBlockLeft", diffX)
            self.game.moveBlockLeft()
            self.touchLastPos = movedPos
        }
        else if diffY < -self.touchThreshold {
            print("moveBlockDown", diffY)
            self.game.moveBlockDown()
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
                // let touchedNode = self.atPoint(movedPos)
                let nodeNames = self.nodes(at: movedPos).compactMap { $0.name }
                print("tapped", diff, nodeNames)
                for name in nodeNames {
                    if let action = self.tapActions[name] {
                        action()
                    }
                }
                let isTappedMenu = nodeNames.contains(self.menuNode.name ?? "")
                if !self.modalNode.isHidden {
                    self.modalNode.run(self.modalTapAction)
                }
                else if isTappedMenu {
                    self.showMenu()
                }
                else {
                    self.game.rotateBlock()
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

        if self.game.isGameOver && self.modalNode.isHidden {
            self.showGameOver(tapAction: {
                _ = firstly {
                    self.hideModal()
                }.ensure {
                    self.startGame()
                }
            })
            return
        }
        if !self.game.isPlayng {
            return
        }
        if lastUpdateTime + gameUpdateInterval <= currentTime {
            self.game.update()
            lastUpdateTime = currentTime
        }
        draw()
    }

    private func startGame() {
        self.game.newGame()

        // 最初ぜったい令和
        if self.reiwaBlock != nil {
            self.game.currentBlock = self.reiwaBlock
        }
    }

    @discardableResult
    private func showMenu() -> Promise<Void> {
        self.game.pauseGame()
        return self.showMenuModal(tapAction: {
            _ = firstly {
                self.hideModal()
            }.ensure {
                self.game.resumeGame()
            }
        })
    }

    @discardableResult
    private func showAbout() -> Promise<Void> {
        self.game.pauseGame()
        return self.showAboutModal(tapAction: {
        // return self.showGameOver(tapAction: {
        // return self.showMenuModal(tapAction: {
            _ = firstly {
                self.hideModal()
            }.ensure {
                self.game.resumeGame()
            }
        })
    }

    @discardableResult
    private func showMenuModal(tapAction: @escaping () -> Void = {}) -> Promise<Void> {
        Analytics.logEvent("show_modal", parameters: ["type": "menu"])
        let (promise, resolver) = Promise<Void>.pending()

        // let seperator = "ーーーーー"
        // let seperator = "一一一一一"
        let makeSeperator = { (yPosition: CGFloat) -> SKShapeNode in
            let node = SKShapeNode(rectOf: CGSize(width: self.size.width / 3, height: 0))
            node.position = CGPoint(x: 0, y: yPosition)
            node.lineWidth = 1
            node.strokeColor = UIColor(hex: "cccccc", alpha: 0.7)
            return node
        }

        let topPosition: CGFloat = 300
        let step: CGFloat = 100
        let aboutLabel = self.makeDefaultLabel(text: "説明", fontSize: 40, yPosition: topPosition - step * 0)
        aboutLabel.name = "aboutLabel"
        self.tapActions["aboutLabel"] = {
            _ = firstly {
                self.hideModal()
            }.ensure {
                self.showAboutModal(tapAction: tapAction)
            }
        }
        let rankingLabel = self.makeDefaultLabel(text: "順位", fontSize: 40, yPosition: topPosition - step * 2)
        rankingLabel.name = "rankingLabel"
        self.tapActions["rankingLabel"] = {
            _ = firstly {
                self.hideModal()
            }.ensure {
                self.showRankingModal(tapAction: tapAction)
            }
        }
        let scoreLabel = self.makeDefaultLabel(text: "得点", fontSize: 40, yPosition: topPosition - step * 4)
        scoreLabel.name = "scoreLabel"
        self.tapActions["scoreLabel"] = {
            _ = firstly {
                self.hideModal()
            }.ensure {
                self.showScoreModal(tapAction: tapAction)
            }
        }
        let settingsLabel = self.makeDefaultLabel(text: "設定", fontSize: 40, yPosition: topPosition - step * 6)
        settingsLabel.name = "settingsLabel"
        self.tapActions["settingsLabel"] = {
            _ = firstly {
                self.hideModal()
            }.ensure {
                self.showSettingsModal(tapAction: tapAction)
            }
        }
        var nodes: [SKNode] = []
        nodes.append(aboutLabel)
        // nodes.append(self.makeDefaultLabel(text: seperator, fontSize: 40, yPosition: topPosition - step * 1))
        nodes.append(makeSeperator(topPosition - step * 1))
        nodes.append(rankingLabel)
        // nodes.append(self.makeDefaultLabel(text: seperator, fontSize: 40, yPosition: topPosition - step * 3))
        nodes.append(makeSeperator(topPosition - step * 3))
        nodes.append(scoreLabel)
        // nodes.append(self.makeDefaultLabel(text: seperator, fontSize: 40, yPosition: topPosition - step * 5))
        nodes.append(makeSeperator(topPosition - step * 5))
        nodes.append(settingsLabel)

        _ = firstly {
            self.showModal(nodes: nodes)
        }.ensure {
            resolver.fulfill(Void())
        }

        return promise
    }

    @discardableResult
    private func showAboutModal(tapAction: @escaping () -> Void = {}) -> Promise<Void> {
        Analytics.logEvent("show_modal", parameters: ["type": "about"])
        let (promise, resolver) = Promise<Void>.pending()

        var nodes: [SKNode] = []
        let titleLabel = self.makeDefaultLabel(text: "令和ぱずる", fontSize: 80, yPosition: 400)
        nodes.append(titleLabel)

        let description = """
            日本の元号を揃えて遊ぶ落ちゲー。
            左右フリックで移動。タップで回転。
            揃った元号の年数が長いほど高得点。
            令和はスペシャルポイント1万点。
            上まで積み上がるとゲームオーバー。
        """
        for (index, desc) in description.split(separator: "\n").enumerated() {
            let label = self.makeDefaultLabel(text: String(desc), fontSize: 40, yPosition: titleLabel.position.y - 150 - 120 * CGFloat(index))
            nodes.append(label)
        }

        let button = self.makeDefaultLabel(text: "閉じる ×", fontSize: 40, yPosition: nodes.last!.position.y - 170)
        nodes.append(button)

        _ = firstly {
            self.showModal(nodes: nodes, tapAction: tapAction)
        }.ensure {
            resolver.fulfill(Void())
        }

        return promise
    }

    @discardableResult
    private func showRankingModal(tapAction: @escaping () -> Void = {}) -> Promise<Void> {
        Analytics.logEvent("show_modal", parameters: ["type": "ranking"])
        let (promise, resolver) = Promise<Void>.pending()

        var nodes: [SKNode] = []
        let titleLabel = self.makeDefaultLabel(text: "順位", fontSize: 80, yPosition: 300)
        nodes.append(titleLabel)

        let rankingNode = SKNode()
        let loadingLabel = self.makeDefaultLabel(text: "読込中...", fontSize: 45, yPosition: 0)
        rankingNode.addChild(loadingLabel)
        nodes.append(rankingNode)

        let button = self.makeDefaultLabel(text: "閉じる ×", fontSize: 40, yPosition: nodes.last!.position.y - 360)
        nodes.append(button)

        _ = firstly {
            self.getRankingData()
        }.done { rankings -> Void in
            rankingNode.removeAllChildren()
            for (index, document) in rankings.enumerated() {
                let data = document.data()
                let rank = self.numKanji[index]
                let name: String = (data["name"] as? String) ?? ""
                let text = "\(rank)位　\(name.isEmpty ? "名無" : name)　\(data["highScore"] ?? 0)"
                let label = self.makeDefaultLabel(text: text, fontSize: 45, yPosition: titleLabel.position.y - 130 - 100 * CGFloat(index))
                rankingNode.addChild(label)
            }
        }
        _ = firstly {
            self.showModal(nodes: nodes, tapAction: tapAction)
        }.ensure {
            resolver.fulfill(Void())
        }

        return promise
    }

    @discardableResult
    private func showScoreModal(tapAction: @escaping () -> Void = {}) -> Promise<Void> {
        Analytics.logEvent("show_modal", parameters: ["type": "score"])
        let (promise, resolver) = Promise<Void>.pending()

        var nodes: [SKNode] = []
        let titleLabel = self.makeDefaultLabel(text: "得点", fontSize: 80, yPosition: 200)
        nodes.append(titleLabel)

        let description = """
            前回得点： \(self.getLastScore())
            最高得点： \(self.getHighScore())
        """
        for (index, desc) in description.split(separator: "\n").enumerated() {
            let label = self.makeDefaultLabel(text: String(desc), fontSize: 40, yPosition: titleLabel.position.y - 150 - 120 * CGFloat(index))
            nodes.append(label)
        }

        let button = self.makeDefaultLabel(text: "閉じる ×", fontSize: 40, yPosition: nodes.last!.position.y - 170)
        nodes.append(button)

        _ = firstly {
            self.showModal(nodes: nodes, tapAction: tapAction)
        }.ensure {
            resolver.fulfill(Void())
        }

        return promise
    }

    @discardableResult
    private func showSettingsModal(tapAction: @escaping () -> Void = {}) -> Promise<Void> {
        Analytics.logEvent("show_modal", parameters: ["type": "settings"])
        let (promise, resolver) = Promise<Void>.pending()

        var nodes: [SKNode] = []
        let titleLabel = self.makeDefaultLabel(text: "設定", fontSize: 80, yPosition: 200)
        nodes.append(titleLabel)

        // let settingsView = SKView(frame: self.view!.frame)
        // let settingsView = SKView()
        // self.view!.addSubview(settingsView)
        var subviews: [UIControl] = []
        let settings = ["名前": self.getName()]
        for (index, setting) in settings.enumerated() {
            let label = self.makeDefaultLabel(text: "\(setting.key)", fontSize: 40, yPosition: titleLabel.position.y - 130 - 120 * CGFloat(index))
            nodes.append(label)

            let size = CGSize(width: 125, height: 30)
            let textField = UITextField(frame: CGRect(origin: self.convertPoint(toView: CGPoint(x: 0 - size.width - 15, y: 30)), size: size))
            textField.backgroundColor = UIColor(hex: "ffffff", alpha: 0.9)
            textField.text = "\(setting.value)"
            textField.font = UIFont(name: "Hiragino Mincho ProN", size: 20)
            textField.borderStyle = .roundedRect
            textField.textAlignment = .center
            textField.delegate = self
            self.textFieldActions[textField] = { text in
                // TODO: generalize
                self.setName(name: text)
            }
            subviews.append(textField)
            self.view!.addSubview(textField)
            // settingsView.addSubview(textField)
            // self.view!.addSubview(settingsView)
        }
        let button = self.makeDefaultLabel(text: "閉じる ×", fontSize: 40, yPosition: nodes.last!.position.y - 290)
        nodes.append(button)
        button.name = "closeButton"
        self.tapActions["closeButton"] = {
            for view in subviews {
                view.removeFromSuperview()
            }
            tapAction()
        }

        _ = firstly {
            self.showModal(nodes: nodes)
        }.ensure {
            resolver.fulfill(Void())
        }

        return promise
    }

    @discardableResult
    private func showGameOver(tapAction: @escaping () -> Void = {}) -> Promise<Void> {
        let (promise, resolver) = Promise<Void>.pending()

        var nodes: [SKNode] = []
        let titleLabel = self.makeDefaultLabel(text: "終了", fontSize: 110, yPosition: 200)
        nodes.append(titleLabel)

        let scoreLabel = self.makeDefaultLabel(text: "得点： \(self.game.score)", fontSize: 70, yPosition: titleLabel.position.y - 170)
        nodes.append(scoreLabel)

        let description = """
            最高得点： \(self.getHighScore())
        """
        for (_, desc) in description.split(separator: "\n").enumerated() {
            let label = self.makeDefaultLabel(text: String(desc), fontSize: 45, yPosition: nodes.last!.position.y - 100)
            nodes.append(label)
        }

        let button = self.makeDefaultLabel(text: "開始↻", fontSize: 45, yPosition: nodes.last!.position.y - 140)
        nodes.append(button)

        _ = firstly {
            self.showModal(nodes: nodes, tapAction: tapAction)
        }.ensure {
            resolver.fulfill(Void())
        }

        return promise
    }

    private func showNotification(title: String, description: String? = nil, tapAction: @escaping () -> Void = {}) -> Promise<Void> {
        let (promise, resolver) = Promise<Void>.pending()

        var nodes: [SKNode] = []
        let titleLabel = self.makeDefaultLabel(text: title, fontSize: 110)
        nodes.append(titleLabel)

        if let description = description {
            for (index, desc) in description.split(separator: "\n").enumerated() {
                let label = self.makeDefaultLabel(text: String(desc), fontSize: 45, yPosition: titleLabel.position.y - 80 - 65 * CGFloat(index))
                nodes.append(label)
            }
        }
        _ = firstly {
            self.showModal(nodes: nodes, tapAction: tapAction)
        }.ensure {
            resolver.fulfill(Void())
        }

        return promise
    }

    // TODO: make modal another view(or scene).
    private func showModal(nodes: [SKNode] = [], tapAction: @escaping () -> Void = {}) -> Promise<Void> {
        let (promise, resolver) = Promise<Void>.pending()

        guard self.modalNode.isHidden else {
            resolver.reject(AppError.common)
            return promise
        }

        for node in nodes {
            self.modalNode.addChild(node)
        }

        self.modalTapAction = SKAction.run(tapAction)

        let fadeIn  = SKAction.fadeIn(withDuration: 0.5)
        let delay   = SKAction.wait(forDuration: TimeInterval(1.0))
        let finally = SKAction.run({
            resolver.fulfill(Void())
        })
        self.mainNode.shouldEnableEffects = true
        self.modalNode.isHidden = false
        self.modalNode.alpha = 0.0
        self.modalNode.run(SKAction.sequence([fadeIn, delay, finally]))

        return promise
    }

    @discardableResult
    private func hideModal() -> Promise<Void> {
        let (promise, resolver) = Promise<Void>.pending()

        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let finally = SKAction.run({
            self.mainNode.shouldEnableEffects = false
            self.modalNode.removeAllChildren()
            self.modalNode.isHidden = true
            resolver.fulfill(Void())
        })
        self.modalNode.run(SKAction.sequence([fadeOut, finally]))

        return promise
    }

    private func makeDefaultLabel(text: String, fontSize: CGFloat = 40, yPosition: CGFloat = 0) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.fontName = "Hiragino Mincho ProN"
        label.fontColor = UIColor(hex: "eeeeee")
        label.fontSize = fontSize
        label.position = CGPoint(x: 0, y: yPosition)
        return label
    }

    private func clearEffect(pair: StonePair) -> Promise<Void> {
        print("clearEffect")
        let (promise, resolver) = Promise<Void>.pending()
        var effectNodes: [SKShapeNode] = []
        let drawClearStone: (Stone, Point) -> Void = { (stone, point) -> Void in
            guard let gengoStone = stone as? GengoStone else {
                return
            }
            let newStone = gengoStone.copy()
            newStone.label.fontColor = UIColor(hex: "FF6666")
            if let newNode = self.drawStone(stone: newStone, x: point.x, y: point.y) {
                newNode.zPosition = 1
                effectNodes.append(newNode)
            }
        }
        drawClearStone(pair.leftStone, pair.leftPoint)
        drawClearStone(pair.rightStone, pair.rightPoint)
        let gengoData = self.getGengoData(pair: pair)
        _ = firstly {
            self.showNotification(title: gengoData?.name ?? "", description: gengoData?.description)
        }.then {
            self.hideModal()
        }.ensure {
            self.mainNode.removeChildren(in: effectNodes)
            resolver.fulfill(Void())
        }
        return promise
    }

    private func calcScore(pair: StonePair) -> Int {
        print("calcScore")
        guard let gengoData = self.getGengoData(pair: pair) else {
            return 0
        }
        print("year_count", gengoData.year_count)
        // 年数の合計をスコアにする
        let sum = gengoData.year_count.reduce(0) { $0 + $1 }
        var score = sum * 10
        if gengoData.name == "令和" {
            score = 10000
        }
        print("score", score)
        return score
    }

    private func getGengoData(pair: StonePair) -> GengoDataItem? {
        var text: String = ""
        for stone in [pair.leftStone, pair.rightStone] {
            guard let gengoStone = stone as? GengoStone else { continue }
            text += String(gengoStone.char)
        }
        let datum = GengoStone.gengoData.first { $0.name == text }
        print(datum ?? "gengo data not found")
        return datum
    }

    private func draw() {
        drawBoard()
        drawCurrentBlock()
        drawNextBlock()
        self.scoreNumLabel.text = String(self.game.score)
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
                guard drawY >= 0 else {
                    continue
                }
                if let newNode = self.drawStone(stone: boardStone, x: drawX, y: drawY) {
                    newNode.lineWidth = 0
                    self.currentBlockNodes.append(newNode)
                }
            }
        }
    }

    private func drawNextBlock() {
        self.nextNode.removeChildren(in: self.nextBlockNodes)
        self.nextBlockNodes.removeAll()
        guard let block = self.game.nextBlock else {
            return
        }
        for (y, row) in block.shape.enumerated() {
            for (_, stone) in row.enumerated() {
                guard let boardStone = stone else {
                    continue
                }
                let newStoneNode = self.makeStoneNode(cornerRadius: 10)
                let label = boardStone.appearance as! SKNode
                let newLabel = label.copy() as! SKNode
                newStoneNode.addChild(newLabel)
                newStoneNode.position = CGPoint(x: 0, y: -1 * CGFloat(y) * self.stoneSize + 44)
                // newStoneNode.lineWidth = 0
                self.nextBlockNodes.append(newStoneNode)
                self.nextNode.addChild(newStoneNode)
            }
        }
    }

    private func drawStone(stone: Stone?, x: Int, y: Int) -> SKShapeNode? {
        let drawY = y - self.game.hiddenRows
        guard drawY >= 0 else {
            return nil
        }
        let newStoneNode = self.makeStoneNode()
        if let unwrappedStone = stone {
            // newStoneNode.strokeColor = unwrappedStone.appearance as! UIColor
            // newStoneNode.fillColor = unwrappedStone.appearance as! UIColor
            let label = unwrappedStone.appearance as! SKNode
            let newLabel = label.copy() as! SKNode
            newStoneNode.addChild(newLabel)
        }
        newStoneNode.position = getBoardPosition(x: x, y: drawY)
        self.mainNode.addChild(newStoneNode)
        return newStoneNode
    }

    private func makeStoneNode(cornerRadius: CGFloat = 0) -> SKShapeNode {
        let stone = SKShapeNode(rectOf: CGSize(width: self.stoneSize, height: self.stoneSize), cornerRadius: cornerRadius)
        stone.lineWidth = 1
        stone.strokeColor = UIColor(hex: "cccccc", alpha: 0.2)
        return stone
    }

    private func getBoardPosition(x: Int, y: Int) -> CGPoint {
        let verticalMargin = self.size.height - self.boardHeight
        return CGPoint(
            x: self.stoneSize * CGFloat(x) - self.size.width/2 + self.stoneSize/2 + self.boardMargin,
            y: -1 * (self.stoneSize * CGFloat(y) - self.size.height/2 + self.stoneSize/2 + verticalMargin - self.boardMargin)
        )
    }

    private func getRankingData() -> Promise<[QueryDocumentSnapshot]> {
        let (promise, resolver) = Promise<[QueryDocumentSnapshot]>.pending()
        let rankingRef = self.db.collection("users").order(by: "highScore", descending: true).limit(to: 5)
        rankingRef.getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                let ranking: [QueryDocumentSnapshot] = querySnapshot!.documents
                resolver.fulfill(ranking)
                // for document in querySnapshot!.documents {
                //     print("\(document.documentID) => \(document.data())")
                // }
            }
        }
        return promise
    }

    private func sendUserData() {
        print("sendUserData")
        guard let uid = self.user?.uid else { return }
        print("uid: \(uid)")
        // self.db.collection("users").document(uid).updateData([
        self.db.collection("users").document(uid).setData([
            "name": "\(self.getName())",
            "highScore": self.getHighScore(),
        ]) { err in
            print("sended")
            if let err = err {
                print("Error adding document: \(err)")
            }
        }
    }

    // TODO: should separate code around UITextField.
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let maxLength = 5
        guard let text = textField.text, let rangeOfTextToReplace = Range(range, in: text) else {
            return false
        }
        let substringToReplace = text[rangeOfTextToReplace]
        let count = text.count - substringToReplace.count + string.count
        return count <= maxLength
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("textFieldShouldReturn before responder\n")
        // textField.resignFirstResponder()
        textField.endEditing(true)
        print("textFieldShouldReturn\n")
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        print("textFieldDidBeginEditing\n")
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        print("textFieldShouldBeginEditing\n")
        return true
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        print("textFieldShouldEndEditing\n")
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        print("textFieldDidEndEditing\n")
        print("\(textField.text ?? "")")
        if let action = self.textFieldActions[textField] {
            action(textField.text ?? "")
        }
    }

    private func getName() -> String {
        return UserDefaults.standard.string(forKey: "name") ?? ""
    }

    private func setName(name: String) {
        UserDefaults.standard.set(name, forKey: "name")
    }

    private func getLastScore() -> Int {
        return UserDefaults.standard.integer(forKey: "lastScore")
    }

    private func setLastScore(score: Int) {
        UserDefaults.standard.set(score, forKey: "lastScore")
    }

    private func getHighScore() -> Int {
        return UserDefaults.standard.integer(forKey: "highScore")
    }

    private func setHighScore(score: Int) {
        UserDefaults.standard.set(score, forKey: "highScore")
    }
}
