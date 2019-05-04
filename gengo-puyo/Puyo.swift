//
//  Puyo.swift
//  gengo-puyo
//
//  Created by motoki-shun on 2019/04/04.
//  Copyright © 2019 motoki-shun. All rights reserved.
//

import Foundation
import PromiseKit

// board上の座標
struct Point: Equatable {
    var x: Int = 0
    var y: Int = 0
}

struct StonePair {
    var leftPoint: Point
    var leftStone: Stone
    var rightPoint: Point
    var rightStone: Stone
}

final class Puyo {
    let cols = 6
    let rows = 12

    let numberOfStone = 2

    let hiddenRows: Int
    let logicalRows: Int

    let stoneCountForClear: Int
    let stoneList: [Stone]
    var clearEffect: (StonePair) -> Promise<Void> = {_ in Promise()}
    var calcScore: (StonePair) -> Int = {_ in 0}
    var score: Int = 0
    var onGameOver: () -> Void = {}
    // TODO: RxSwiftかKVOか何かでいい感じにしたい

    var board: [[Stone?]]
    var currentBlock: Block!
    var nextBlock: Block!
    var isPlayng: Bool = false
    var isGameOver: Bool = false
    var isEffecting: Bool = false

    init(stoneList: [Stone], stoneCountForClear: Int = 4) {
        self.stoneList = stoneList
        self.stoneCountForClear = stoneCountForClear

        self.hiddenRows = self.numberOfStone
        self.logicalRows = self.rows + self.hiddenRows

        self.board = Array(repeating: Array(repeating: nil, count: self.cols), count: self.logicalRows)

        self.currentBlock = generateBlock()
        self.nextBlock = generateBlock()
    }

    func newGame() {
        self.board = Array(repeating: Array(repeating: nil, count: self.cols), count: self.logicalRows)
        self.score = 0
        self.setNextBlock()
        self.isGameOver = false
        self.isPlayng = true
    }

    func quitGame() {
        self.isPlayng = false
        self.isGameOver = true
        self.onGameOver()
    }

    func pauseGame() {
        self.isPlayng = false
    }

    func resumeGame() {
        self.isPlayng = true
    }

    func update() {
        if self.isEffecting {
            print("skip update for isEffecting")
            return
        }
        if self.moveBlockDown() {
            return
        }
        self.freeze()
        self.dropStones()
        // while self.clearStones() {
        //     self.dropStones()
        // }
        self.isEffecting = true
        self.currentBlock = nil
        _ = firstly {
            self.clearLoop()
        }.ensure {
            self.setNextBlock()
            if self.checkGameOver() {
                print("Game Over!")
                self.quitGame()
            }
            self.isEffecting = false
        }
    }

    private func clearLoop() -> Promise<Any> {
        return self.clearStones().then { success -> Promise<Any> in
            if success {
                self.dropStones()
                return self.clearLoop()
            }
            return Promise.value(())
        }
    }

    private func setNextBlock() {
        self.currentBlock = self.nextBlock
        self.nextBlock = generateBlock()
    }

    private func generateBlock() -> Block {
        return Block(stones: [stoneList.randomElement()!, stoneList.randomElement()!], x: self.cols / 2, y: 0)
    }

    private func freeze() {
        guard self.currentBlock != nil else { return }
        for (y, row) in self.currentBlock.shape.enumerated() {
            for (x, stone) in row.enumerated() {
                let boardX = x + self.currentBlock.x
                let boardY = y + self.currentBlock.y
                if stone == nil || boardY < 0 {
                    continue
                }
                self.board[boardY][boardX] = stone
            }
        }
    }

    private func dropStones() {
        let transposed = transpose(input: self.board)
        let droppedBoard = transposed.map {column -> [Stone?] in
            var newColumn = column.filter({ $0 != nil })
            let diff = column.count - newColumn.count
            newColumn = Array(repeating: nil, count: diff) + newColumn
            return newColumn
        }
        self.board = transpose(input: droppedBoard)
    }

    private func clearStones() -> Promise<Bool> {
        let (promise, resolver) = Promise<Bool>.pending()
        var checkingBoard: [[[Point]]] = Array(repeating: Array(repeating: [], count: self.cols), count: self.logicalRows)
        var checkingPairs: [StonePair] = []
        for (y, row) in self.board.enumerated() {
            for (x, stone) in row.enumerated() {
                if stone == nil {
                    continue
                }
                // print(stone!)
                // print(type(of: stone!))
                if x > 0, let leftStone = self.board[y][x - 1] {
                    // if leftStone == stone! {
                    if leftStone.isEqual(stone!) {
                        checkingBoard[y][x] = (checkingBoard[y][x] + checkingBoard[y][x - 1] + [Point(x: x - 1, y: y), Point(x: x, y: y)]).unique
                        checkingPairs.append(StonePair(
                            leftPoint: Point(x: x-1, y: y),
                            leftStone: leftStone,
                            rightPoint: Point(x: x, y: y),
                            rightStone: stone!
                        ))
                        print("x", x, checkingBoard[y][x])
                    }
                }
                if y > 0, let upperStone = self.board[y - 1][x] {
                    // if upperStone == stone! {
                    if upperStone.isEqual(stone!) {
                        checkingBoard[y][x] = (checkingBoard[y][x] + checkingBoard[y - 1][x] + [Point(x: x, y: y - 1), Point(x: x, y: y)]).unique
                        checkingPairs.append(StonePair(
                            leftPoint: Point(x: x, y: y-1),
                            leftStone: upperStone,
                            rightPoint: Point(x: x, y: y),
                            rightStone: stone!
                        ))
                        print("y", y, checkingBoard[y][x])
                    }
                }
            }
        }
        print("board", self.board.map { $0.map { $0 != nil ? $0!.kind : nil } })
        print("checkingBoard", checkingBoard)
        print("checkingPairs", checkingPairs)
        // print("checkingBoard flattened", Array(checkingBoard.joined()))
        let clearPoints = checkingBoard.joined().reduce([]) { (acc, val) in
            val.unique.count >= self.stoneCountForClear ? acc + val : acc
        }.unique
        print("clearPoints", clearPoints)
        // for point in clearPoints {
        //     if let stone = self.board[point.y][point.x] {
        //         firstly {
        //             self.clearEffect(stone)
        //         }.ensure {
        //             print("ensure")
        //             self.board[point.y][point.x] = nil
        //         }.catch { error in
        //             print("catch")
        //             print(error)
        //         }.finally {
        //             print("finally")
        //             resolver.fulfill(!clearPoints.isEmpty)
        //         }
        //     }
        // }
        // TODO: stoneCountForClearが2以外のときはいったん忘れる
        var pairPromises = Promise()
        for pair in checkingPairs {
            pairPromises = pairPromises.then {
                self.clearEffect(pair).ensure {
                    self.score += self.calcScore(pair)
                    self.board[pair.leftPoint.y][pair.leftPoint.x] = nil
                    self.board[pair.rightPoint.y][pair.rightPoint.x] = nil
                }
            }
        }
        _ = pairPromises.done {
            resolver.fulfill(!clearPoints.isEmpty)
        }
        return promise
    }

    @discardableResult
    func moveBlockLeft() -> Bool {
        guard self.currentBlock != nil else { return false }
        let isValid = self.validate(offsetX: -1, offsetY: 0, block: self.currentBlock)
        if isValid {
            self.currentBlock.moveLeft()
        }
        return isValid
    }

    @discardableResult
    func moveBlockRight() -> Bool {
        guard self.currentBlock != nil else { return false }
        let isValid = self.validate(offsetX: 1, offsetY: 0, block: self.currentBlock)
        if isValid {
            self.currentBlock.moveRight()
        }
        return isValid
    }

    @discardableResult
    func moveBlockDown() -> Bool {
        guard self.currentBlock != nil else { return false }
        let isValid = self.validate(offsetX: 0, offsetY: 1, block: self.currentBlock)
        if isValid {
            self.currentBlock.moveDown()
        }
        return isValid
    }

    @discardableResult
    func rotateBlock() -> Bool {
        guard var rotatedBlock = self.currentBlock else { return false }
        rotatedBlock.rotate()
        let isValid = self.validate(block: rotatedBlock)
        if isValid {
            self.currentBlock = rotatedBlock
        }
        return isValid
    }

    private func validate(offsetX: Int = 0, offsetY: Int = 0, block: Block) -> Bool {
        let nextX = block.x + offsetX
        let nextY = block.y + offsetY
        for (y, row) in block.shape.enumerated() {
            for (x, stone) in row.enumerated() {
                if stone == nil {
                    continue
                }
                let boardX = x + nextX
                let boardY = y + nextY
                let isOutsideLeftWall = boardX < 0
                let isOutsideRightWall = boardX >= self.cols
                let isUnderBottom = boardY >= self.logicalRows
                if isOutsideLeftWall || isOutsideRightWall || isUnderBottom {
                    print("isOutsideLeftWall: \(isOutsideLeftWall), isOutsideRightWall: \(isOutsideRightWall), isUnderBottom: \(isUnderBottom)")
                    return false
                }
                if self.board[boardY][boardX] != nil { // isExistsBlock
                    print("isExistsBlock! self.board[boardY][boardX]: \(String(describing: self.board[boardY][boardX]))")
                    return false
                }
            }
        }
        return true
    }

    private func checkGameOver() -> Bool {
        guard self.currentBlock != nil else { return false }
        let canDown = self.validate(offsetY: 1, block: self.currentBlock)
        let boardY = self.currentBlock.y
        let isGameOver = !canDown && boardY < self.hiddenRows
        if isGameOver {
            print("isGameOver! boardY: \(boardY), canDown: \(canDown), currentBlock: \(String(describing: self.currentBlock))")
        }
        return isGameOver
    }
}
