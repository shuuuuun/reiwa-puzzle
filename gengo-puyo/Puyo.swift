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

class Puyo {
    let cols = 6
    let rows = 12

    let numberOfStone = 2

    let hiddenRows: Int
    let logicalRows: Int

    let stoneCountForClear: Int
    let stoneList: [Stone]
    var clearEffect: (Stone) -> Promise<Void>

    var board: [[Stone?]]
    var currentBlock: Block!
    var nextBlock: Block!
    var isPlayng: Bool = false

    init(stoneList: [Stone], stoneCountForClear: Int = 4, clearEffect: @escaping (Stone) -> Promise<Void> = {_ in Promise()}) {
        // self.stoneList = stoneAppearanceList.enumerated().map { Stone(kind: $0.0, appearance: $0.1) }
        self.stoneList = stoneList
        self.stoneCountForClear = stoneCountForClear
        self.clearEffect = clearEffect

        self.hiddenRows = self.numberOfStone
        self.logicalRows = self.rows + self.hiddenRows

        self.board = Array(repeating: Array(repeating: nil, count: self.cols), count: self.rows)

        self.currentBlock = generateBlock()
        self.nextBlock = generateBlock()
    }

    func newGame() {
        self.isPlayng = true
        self.setNextBlock()
    }

    func quitGame() {
        self.isPlayng = false
    }

    func update() {
        if self.moveBlockDown() {
            return
        }
        self.freeze()
        self.dropStones()
        // while self.clearStones() {
        //     self.dropStones()
        // }
        _ = self.clearLoop()
        if self.checkGameOver() {
            print("Game Over!")
            self.quitGame()
            return
        }
        self.setNextBlock()
    }

    func clearLoop() -> Promise<Void> {
        return self.clearStones().done {success in
            if success {
                self.dropStones()
                _ = self.clearLoop()
            }
        }
    }

    func setNextBlock() {
        self.currentBlock = self.nextBlock
        self.nextBlock = generateBlock()
    }

    private func generateBlock() -> Block {
        return Block(stones: [stoneList.randomElement()!, stoneList.randomElement()!], x: cols / 2, y: 0)
    }

    func freeze() {
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

    func dropStones() {
        let transposed = transpose(input: self.board)
        let droppedBoard = transposed.map {column -> [Stone?] in
            var newColumn = column.filter({ $0 != nil })
            let diff = column.count - newColumn.count
            newColumn = Array(repeating: nil, count: diff) + newColumn
            return newColumn
        }
        self.board = transpose(input: droppedBoard)
    }

    func clearStones() -> Promise<Bool> {
        let (promise, resolver) = Promise<Bool>.pending()
        var checkingBoard: [[[Point]]] = Array(repeating: Array(repeating: [], count: self.cols), count: self.rows)
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
        for point in clearPoints {
            if let stone = self.board[point.y][point.x] {
                firstly {
                    self.clearEffect(stone)
                // }.then {_ in 
                //     print("then")
                // }.done {
                //     print("done")
                }.ensure {
                    print("ensure")
                    self.board[point.y][point.x] = nil
                }.catch { error in
                    print("catch")
                    print(error)
                }.finally {
                    print("finally")
                    resolver.fulfill(!clearPoints.isEmpty)
                }
            }
        }
        // return !clearPoints.isEmpty
        return promise
    }

    func moveBlockLeft() -> Bool {
        let isValid = self.validate(offsetX: -1, offsetY: 0, block: self.currentBlock)
        if isValid {
            self.currentBlock.moveLeft()
        }
        return isValid
    }

    func moveBlockRight() -> Bool {
        let isValid = self.validate(offsetX: 1, offsetY: 0, block: self.currentBlock)
        if isValid {
            self.currentBlock.moveRight()
        }
        return isValid
    }

    func moveBlockDown() -> Bool {
        let isValid = self.validate(offsetX: 0, offsetY: 1, block: self.currentBlock)
        if isValid {
            self.currentBlock.moveDown()
        }
        return isValid
    }

    func rotateBlock() -> Bool {
        var rotatedBlock = self.currentBlock! // copy
        rotatedBlock.rotate()
        let isValid = self.validate(offsetX: 0, offsetY: 0, block: rotatedBlock)
        if isValid {
            self.currentBlock = rotatedBlock
        }
        return isValid
    }

    func validate(offsetX: Int, offsetY: Int, block: Block) -> Bool {
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
                let isOutsideRightWall = boardX >= cols
                let isUnderBottom = boardY >= logicalRows
                let isOutsideBoard = boardY >= self.board.count || boardX >= self.board[boardY].count
                if isOutsideLeftWall || isOutsideRightWall || isUnderBottom || isOutsideBoard {
                    return false
                }
                if self.board[boardY][boardX] != nil { // isExistsBlock
                    return false
                }
            }
        }
        return true
    }

    func checkGameOver() -> Bool {
        var isGameOver = true
        let boardY = self.currentBlock.y + (self.numberOfStone - 1)
        if boardY >= self.hiddenRows {
            isGameOver = false
        }
        return isGameOver
    }
}
