//
//  PuyoBlock.swift
//  gengo-puyo
//
//  Created by motoki-shun on 2019/04/14.
//  Copyright © 2019 motoki-shun. All rights reserved.
//

import Foundation

struct Block {
    var stones: [Stone]
    var shape: [[Stone?]]
    var x: Int = 0
    var y: Int = 0

    init(stones: [Stone], x: Int, y: Int) {
        self.stones = stones
        self.x = x
        self.y = y
        self.shape = Array(repeating: Array(repeating: nil, count: stones.count), count: stones.count)
        for (index, _) in self.shape.enumerated() {
            self.shape[index][0] = stones[index]
        }
        // print(self.shape)
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
        let count = self.stones.count
        var newShape: [[Stone?]] = Array(repeating: Array(repeating: nil, count: count), count: count)
        for (y, row) in newShape.enumerated() {
            for (x, _) in row.enumerated() {
                newShape[y][x] = self.shape[count - 1 - x][y]
            }
        }
        self.shape = newShape
    }
}
