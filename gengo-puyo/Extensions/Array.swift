//
//  Array.swift
//  gengo-puyo
//
//  Created by motoki-shun on 2019/04/06.
//  Copyright © 2019 motoki-shun. All rights reserved.
//

extension Array where Element: Equatable {
    var unique: [Element] {
        return reduce([Element]()) { $0.contains($1) ? $0 : $0 + [$1] }
    }

    // var transpose: [[Element]] {
    //     if self.isEmpty { return [[Element]]() }
    //     var out = [[Element]](repeating: [Element](), count: self[0].count)
    //     for outer in self {
    //         for (index, inner) in outer.enumerated() {
    //             out[index].append(inner)
    //         }
    //     }
    //     return out
    // }
    // public static func transpose<T>(input: [[T]]) -> [[T]] {
    //     if input.isEmpty { return [[T]]() }
    //     var out = [[T]](repeating: [T](), count: input[0].count)
    //     for outer in input {
    //         for (index, inner) in outer.enumerated() {
    //             out[index].append(inner)
    //         }
    //     }
    //     return out
    // }
}

// TODO: インスタンスメソッドにしたい
public func transpose<T>(input: [[T]]) -> [[T]] {
    if input.isEmpty { return [[T]]() }
    var out = [[T]](repeating: [T](), count: input[0].count)
    for outer in input {
        for (index, inner) in outer.enumerated() {
            out[index].append(inner)
        }
    }
    return out
}
