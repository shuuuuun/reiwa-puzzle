//
//  PuyoStone.swift
//  gengo-puyo
//
//  Created by motoki-shun on 2019/04/14.
//  Copyright © 2019 motoki-shun. All rights reserved.
//

import Foundation

struct Stone {
    var kind: Int
    var appearance: Any

    init(kind: Int, appearance: Any) {
        self.kind = kind
        self.appearance = appearance
    }

    static func == (left: Stone, right: Stone) -> Bool {
        return left.kind == right.kind
    }
    static func != (left: Stone, right: Stone) -> Bool {
        return !(left == right)
    }
}
