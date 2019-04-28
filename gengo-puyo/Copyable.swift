//
//  Copyable.swift
//  gengo-puyo
//
//  Created by motoki-shun on 2019/04/28.
//  Copyright © 2019 motoki-shun. All rights reserved.
//

protocol Copyable {
    init(instance: Self)
}

extension Copyable {
    func copy() -> Self {
        return Self.init(instance: self)
    }
}
