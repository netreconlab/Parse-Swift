//
//  InMemoryPrimitiveStore.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/12/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

/// A `ParsePrimitiveStorable` that lives in memory for unit testing purposes.
/// It works by encoding / decoding all values just like a real `Codable` store would
/// but it stores all values as `Data` blobs in memory.
actor InMemoryPrimitiveStore: ParsePrimitiveStorable {
    let decoder = ParseCoding.jsonDecoder()
    let encoder = ParseCoding.jsonEncoder()
    var storage = [String: Data]()

    func delete(valueFor key: String) throws {
        storage[key] = nil
    }

    func deleteAll() throws {
        storage.removeAll()
    }

    func get<T>(valueFor key: String) throws -> T? where T: Decodable {
        guard let data = storage[key] else {
            return nil
        }
        return try decoder.decode(T.self, from: data)
    }

    func set<T>(_ object: T, for key: String) throws where T: Encodable {
        let data = try encoder.encode(object)
        storage[key] = data
    }

}
