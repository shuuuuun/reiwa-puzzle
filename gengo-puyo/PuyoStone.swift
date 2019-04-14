//
//  PuyoStone.swift
//  gengo-puyo
//
//  Created by motoki-shun on 2019/04/14.
//  Copyright © 2019 motoki-shun. All rights reserved.
//

import Foundation

protocol Stone {
    var kind: Int { get set }
    var appearance: Any { get set }

    static func == (left: Self, right: Self) -> Bool
    static func != (left: Self, right: Self) -> Bool
}

extension Stone {
    static func == (left: Self, right: Self) -> Bool {
        return left.kind == right.kind
    }

    static func != (left: Self, right: Self) -> Bool {
        return !(left == right)
    }
}

struct ColorStone: Stone {
    var kind: Int
    var appearance: Any

    static func == (left: ColorStone, right: ColorStone) -> Bool {
        return left.kind == right.kind
    }

    static func != (left: ColorStone, right: ColorStone) -> Bool {
        return !(left == right)
    }
}

struct GengoStone: Stone {
    var kind: Int
    var appearance: Any

    static func == (left: GengoStone, right: GengoStone) -> Bool {
        return left.kind == right.kind
    }
    static func != (left: GengoStone, right: GengoStone) -> Bool {
        return !(left == right)
    }
}
