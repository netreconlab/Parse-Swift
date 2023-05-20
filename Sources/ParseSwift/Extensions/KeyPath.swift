//
//  KeyPath.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/19/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

// Reference: https://stackoverflow.com/a/76094048/4639041

extension KeyPath {

    var string: String {
        let me = String(describing: self)
        let dropLeading =  "\\" + String(describing: Root.self) + "."
        let keyPath = "\(me.dropFirst(dropLeading.count))"
        return keyPath
    }

}
