//
//  Puyo.swift
//  gengo-puyo
//
//  Created by motoki-shun on 2019/04/04.
//  Copyright © 2019 motoki-shun. All rights reserved.
//

import Foundation

struct Stone {
    var color: String

    init(color: String) {
        self.color = color
    }
}

struct Block {
    var stones: [Stone]
    var x: Int = 0
    var y: Int = 0

    init(stones: [Stone], x: Int, y: Int) {
        self.stones = stones
        self.x = x
        self.y = y
    }

    mutating func moveLeft() {
        self.x -= 1
    }

    mutating func moveRight() {
        self.x += 1
    }

    mutating func moveDown() {
        self.y += 1
    }

    mutating func rotate() {
        // TODO: block rotate
    }
}

class Puyo {
    let cols = 6
    let rows = 12

    let number_of_stone = 2

    let hidden_rows: Int
    let logical_rows: Int

    // let start_x = Math.floor((coLs - nuMber_of_stone) / 2)
    // let start_y = 0

    let stone_list: [Stone] = Array(repeating: Stone(color: "green"), count: 10)

    var board: [[Int]]
    var currentBlock: Block
    var nextBlock: Block?
    var isPlayng: Bool = false

    init() {
        self.hidden_rows = self.number_of_stone
        self.logical_rows = self.rows + self.hidden_rows

        self.board = Array(repeating: Array(repeating: 0, count: self.cols), count: self.rows)

        self.nextBlock = Block(stones: [stone_list.randomElement()!, stone_list.randomElement()!], x: 0, y: 0)
        self.currentBlock = Block(stones: [stone_list.randomElement()!, stone_list.randomElement()!], x: 0, y: 0)
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
        self.clearLines()
        if self.checkGameOver() {
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
        self.nextBlock = Block(stones: [stone_list.randomElement()!, stone_list.randomElement()!], x: 0, y: 0)
    }

    func freeze() {
        // for y := 0; y < number_of_block; y++ {
        //   for x := 0; x < number_of_block; x++ {
        //     boardX := x + self.currentBlock.x
        //     boardY := y + self.currentBlock.y
        //     if self.currentBlock.shape[y][x] == 0 || boardY < 0 {
        //       continue
        //     }
        //     if self.currentBlock.shape[y][x] != 0 {
        //       self.board[boardY][boardX] = self.currentBlock.blockId + 1
        //     } else {
        //       self.board[boardY][boardX] = 0
        //     }
        //   }
        // }
    }

    func clearLines() {
        // var filledRowList []int
        // for y := logical_rows - 1; y >= 0; y-- {
        //   isRowFilled := !contains(self.board[y], 0)
        //   if !isRowFilled {
        //     continue
        //   }
        //   filledRowList = append(filledRowList, y)
        // }
        // if len(filledRowList) > 0 {
        //   var newBoard [][]int
        //   for range filledRowList {
        //     blankRow := make([]int, cols)
        //     newBoard = append(newBoard, blankRow)
        //   }
        //   for i, row := range self.board {
        //     isRowFilled := contains(filledRowList, i)
        //     if isRowFilled {
        //       continue
        //     }
        //     newBoard = append(newBoard, row)
        //   }
        //   self.board = newBoard
        // }
    }

    func moveBlockLeft() -> Bool {
        // isValid := self.validate(-1, 0, self.currentBlock)
        // if isValid {
        //   self.currentBlock.moveLeft()
        // }
        // return isValid
        return true
    }

    func moveBlockRight() -> Bool {
        // isValid := self.validate(1, 0, self.currentBlock)
        // if isValid {
        //   self.currentBlock.moveRight()
        // }
        // return isValid
        return true
    }

    func moveBlockDown() -> Bool {
        // // isValid := self.validate(0, 1)
        // isValid := self.validate(0, 1, self.currentBlock)
        // if isValid {
        //   self.currentBlock.moveDown()
        // }
        // return isValid
        return true
    }

    func rotateBlock() -> Bool {
        // rotatedBlock := self.currentBlock // copy
        // rotatedBlock.rotate()
        // isValid := self.validate(0, 0, rotatedBlock)
        // if isValid {
        //   self.currentBlock = rotatedBlock
        // }
        // return isValid
        return true
    }

    func validate(offsetX: Int, offsetY: Int, block: Block) -> Bool {
        // // block = block || self.currentBlock
        // nextX := block.x + offsetX
        // nextY := block.y + offsetY
        // if block.shape == nil {
        //   return false
        // }
        // for y := 0; y < number_of_block; y++ {
        //   for x := 0; x < number_of_block; x++ {
        //     if block.shape[y][x] == 0 {
        //       continue
        //     }
        //     boardX := x + nextX
        //     boardY := y + nextY
        //     isOutsideLeftWall := boardX < 0
        //     isOutsideRightWall := boardX >= cols
        //     isUnderBottom := boardY >= logical_rows
        //     isOutsideBoard := boardY >= len(self.board) || boardX >= len(self.board[boardY])
        //     if isOutsideLeftWall || isOutsideRightWall || isUnderBottom || isOutsideBoard {
        //       return false
        //     }
        //     if self.board[boardY][boardX] != 0 { // isExistsBlock
        //       return false
        //     }
        //   }
        // }
        return true
    }

    func checkGameOver() -> Bool {
        // isGameOver := true
        // boardY := self.currentBlock.y + (number_of_block - 1)
        // if boardY >= hidden_rows {
        //   isGameOver = false
        // }
        // return isGameOver
        return false
    }
}
