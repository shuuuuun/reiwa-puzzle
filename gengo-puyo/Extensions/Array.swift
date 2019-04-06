//
//  Array.swift
//  gengo-puyo
//
//  Created by motoki-shun on 2019/04/06.
//  Copyright © 2019 motoki-shun. All rights reserved.
//

//extension Array where Element: Equatable {
//    var unique: [Element] {
//        return reduce([]) { $0.0.contains($0.1) ? $0.0 : $0.0 + [$0.1] }
//    }
//}
extension Array where Element: Equatable {
    var unique: [Element] {
        return reduce([Element]()) { $0.contains($1) ? $0 : $0 + [$1] }
    }
}
//extension Array where Element : Equatable {
//    var unique: [Element] {
//        var uniqueValues: [Element] = []
//        forEach { item in
//            if !uniqueValues.contains(item) {
//                uniqueValues += [item]
//            }
//        }
//        return uniqueValues
//    }
//}
