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
struct InMemoryPrimitiveStore: ParsePrimitiveStorable {
    let synchronizationQueue: DispatchQueue
    let decoder = ParseCoding.jsonDecoder()
    let encoder = ParseCoding.jsonEncoder()
    var storage = [String: Data]()

    init() {
        synchronizationQueue = DispatchQueue(label: "inMemory.primitiveStore",
                                             qos: .default,
                                             attributes: .concurrent,
                                             autoreleaseFrequency: .inherit,
                                             target: nil)
    }

    mutating func delete(valueFor key: String) throws {

        synchronizationQueue.sync(flags: .barrier) {
            storage[key] = nil
        }

    }

    mutating func deleteAll() throws {

        synchronizationQueue.sync {
            storage.removeAll()
        }

    }

    mutating func get<T>(valueFor key: String) throws -> T? where T: Decodable {

        guard let data = synchronizationQueue.sync(execute: { () -> Data? in
            return storage[key]
        }) else {
            return nil
        }
        return try decoder.decode(T.self, from: data)

    }

    mutating func set<T>(_ object: T, for key: String) throws where T: Encodable {

        let data = try encoder.encode(object)
        synchronizationQueue.sync(flags: .barrier) {
            storage[key] = data
        }

    }
}
