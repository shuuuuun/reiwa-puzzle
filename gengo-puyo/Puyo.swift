//
//  Puyo.swift
//  gengo-puyo
//
//  Created by motoki-shun on 2019/04/04.
//  Copyright © 2019 motoki-shun. All rights reserved.
//

import Foundation

class Puyo {
    let cols = 6
    let rows = 12

    let numberOfStone = 2

    let hiddenRows: Int
    let logicalRows: Int

    let stoneCountForClear: Int
    let stoneList: [Stone]

    var board: [[Stone?]]
    var currentBlock: Block!
    var nextBlock: Block!
    var isPlayng: Bool = false

    init(stoneList: [Stone], stoneCountForClear: Int = 4) {
        // self.stoneList = stoneAppearanceList.enumerated().map { Stone(kind: $0.0, appearance: $0.1) }
        self.stoneList = stoneList
        self.stoneCountForClear = stoneCountForClear

        self.hiddenRows = self.numberOfStone
        self.logicalRows = self.rows + self.hiddenRows

        self.board = Array(repeating: Array(repeating: nil, count: self.cols), count: self.rows)
    }

    func newGame() {
        self.isPlayng = true
        self.createCurrentBlock()
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
        while self.clearStones() {
            self.dropStones()
        }
        if self.checkGameOver() {
            print("Game Over!")
            self.quitGame()
            return
        }
        self.createCurrentBlock()
        self.createNextBlock()
    }

    func createCurrentBlock() {
        if self.nextBlock == nil {
            self.createNextBlock()
        }
        self.currentBlock = self.nextBlock!
    }

    func createNextBlock() {
        self.nextBlock = Block(stones: [stoneList.randomElement()!, stoneList.randomElement()!], x: cols / 2, y: 0)
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

    func clearStones() -> Bool {
        var checkingBoard: [[[[Int]]]] = Array(repeating: Array(repeating: [], count: self.cols), count: self.rows)
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
                        checkingBoard[y][x] = (checkingBoard[y][x] + checkingBoard[y][x - 1] + [[x - 1, y], [x, y]]).unique
                        print("x", x, checkingBoard[y][x])
                    }
                }
                if y > 0, let upperStone = self.board[y - 1][x] {
                    // if upperStone == stone! {
                    if upperStone.isEqual(stone!) {
                        checkingBoard[y][x] = (checkingBoard[y][x] + checkingBoard[y - 1][x] + [[x, y - 1], [x, y]]).unique
                        print("y", y, checkingBoard[y][x])
                    }
                }
            }
        }
        print("board", self.board.map { $0.map { $0 != nil ? $0!.kind : nil } })
        print("checkingBoard", checkingBoard)
        // print("checkingBoard flattened", Array(checkingBoard.joined()))
        let clearPoints = checkingBoard.joined().reduce([]) { (acc, val) in
            val.unique.count >= self.stoneCountForClear ? acc + val : acc
        }.unique
        print("clearPoints", clearPoints)
        for point in clearPoints {
            self.board[point[1]][point[0]] = nil
        }
        return !clearPoints.isEmpty
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
