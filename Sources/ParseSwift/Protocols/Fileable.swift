//
//  Fileable.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/27/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

protocol Fileable: ParseEncodable, ParseTypeable, Identifiable {
    var type: String { get }
    var name: String { get set }
    var url: URL? { get set }
}

extension Fileable {
    var isSaved: Bool {
        return url != nil
    }
}
