//
//  PuyoStone.swift
//  gengo-puyo
//
//  Created by motoki-shun on 2019/04/14.
//  Copyright © 2019 motoki-shun. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

class Stone {
    var kind: Int = 0
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

class ColorStone: Stone {
    var color: UIColor
    override var appearance: Any {
        get {
            return color
        }
        set {
            if newValue is UIColor {
                color = newValue as! UIColor
            } else {
                print("incorrect type!")
            }
        }
    }

    init(kind: Int, appearance: UIColor) {
        self.color = appearance
        super.init(kind: kind, appearance: appearance)
    }
}

class GengoStone: Stone {
    static var gengoList: Array<String> = getGengoList()

    var char: Character
    var label: SKLabelNode
    override var appearance: Any {
        get {
            return label
        }
        set {
            if newValue is SKLabelNode {
                label = newValue as! SKLabelNode
            } else {
                print("incorrect type!")
            }
        }
    }

    init(kind: Int, appearance: SKLabelNode, char: Character) {
        self.label = appearance
        self.char = char
        super.init(kind: kind, appearance: appearance)
    }

    static func == (left: GengoStone, right: GengoStone) -> Bool {
        return left.kind == right.kind
    }
    static func != (left: GengoStone, right: GengoStone) -> Bool {
        return !(left == right)
    }

    private static func getGengoList() -> Array<String> {
        guard let text = self.getTextFileData("gengo") else {
            return []
        }
        let gengoAry = text.split(separator: "\n").map(String.init)
        return gengoAry
    }

    private static func getTextFileData(_ fileName: String) -> String? {
        guard let filePath = Bundle.main.path(forResource: fileName, ofType: "txt") else {
            print("The file is not found! \(fileName)")
            return nil
        }
        let fileUrl = URL(fileURLWithPath: filePath)
        print(filePath, fileUrl)
        guard let data = try? String(contentsOf: fileUrl, encoding: String.Encoding.utf8) else {
            print("Failed to load text file!")
            return nil
        }
        print(data)
        return data
    }
}
