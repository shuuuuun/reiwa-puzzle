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

class Stone: Copyable {
    var kind: Int = 0
    var appearance: Any

    init(kind: Int, appearance: Any) {
        self.kind = kind
        self.appearance = appearance
    }

    required init(instance: Stone) {
        self.kind = instance.kind
        self.appearance = instance.appearance
    }

    static func == (left: Stone, right: Stone) -> Bool {
        print("Stone ==")
        return left.kind == right.kind
    }

    static func != (left: Stone, right: Stone) -> Bool {
        return !(left == right)
    }

    func isEqual(_ target: Stone) -> Bool {
        // print("Stone isEqual")
        return self.kind == target.kind
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

    required init(instance: Stone) {
        let instance = instance as! ColorStone
        self.color = instance.color
        super.init(instance: instance)
    }
}

class GengoStone: Stone {
    static var gengoList: Array<String> = getGengoList()
    static var gengoData: [GengoDataItem] = getGengoData()

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

    required init(instance: Stone) {
        let instance = instance as! GengoStone
        self.char = instance.char
        self.label = instance.label.copy() as! SKLabelNode
        super.init(instance: instance)
    }

    static func == (left: GengoStone, right: GengoStone) -> Bool {
    // override static func == (left: Stone, right: Stone) -> Bool {
        print("comparing GengoStone: \(left.char), \(right.char)")
        return left.char == right.char
    }
    static func != (left: GengoStone, right: GengoStone) -> Bool {
        return !(left == right)
    }

    // func isEqual(_ target: GengoStone) -> Bool {
    override func isEqual(_ target: Stone) -> Bool {
        // print("GengoStone isEqual")
        let text = String([self.char, (target as! GengoStone).char])
        let isContains = GengoStone.gengoList.contains(text)
        // print(text, isContains)
        return isContains
    }

    private static func getGengoList() -> Array<String> {
        return GengoStone.gengoData.map { $0.name }
        // guard let text = self.getTextFileData("gengo") else {
        //     return []
        // }
        // let gengoAry = text.split(separator: "\n").map(String.init)
        // return gengoAry
    }

    private static func getGengoData() -> [GengoDataItem] {
        let jsonStr = self.getTextFileData("gengo_data", ofType: "json")!
        let jsonData = jsonStr.data(using: .utf8)!
        let data = try! JSONDecoder().decode([GengoDataItem].self, from: jsonData)
        print(data)
        return data
    }

    private static func getCSVData() -> [[String]] {
        var data: [[String]] = []
        guard let csvStr = self.getTextFileData("gengo_data", ofType: "csv") else {
            return data
        }
        csvStr.enumerateLines { (line, stop) in
            data.append(line.components(separatedBy: ","))
        }
        print(data)
        return data
    }

    private static func getTextFileData(_ fileName: String, ofType: String = "txt") -> String? {
        guard let filePath = Bundle.main.path(forResource: fileName, ofType: ofType) else {
            print("The file is not found! \(fileName).\(ofType)")
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
//extension GengoStone {
//    static func == (left: GengoStone, right: GengoStone) -> Bool {
//        print("comparing GengoStone: \(left.char), \(right.char)")
//        return left.char == right.char
//    }
//    static func != (left: GengoStone, right: GengoStone) -> Bool {
//        return !(left == right)
//    }
//}

struct GengoDataItem: Codable {
    let name: String
    let era: [String]
    let yomi: [String]
    let begin_date: [String]
    let end_date: [String]
    let year_count: [String]
    let emperor_name: [String]
    let reason: [String]
}
