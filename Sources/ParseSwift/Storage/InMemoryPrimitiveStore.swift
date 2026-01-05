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
    let decoder = ParseCoding.jsonDecoder()
    let encoder = ParseCoding.jsonEncoder()
	private let lock = NSLock()
	private var _storage = [String: Data]()
	var storage: [String: Data] {
		get {
			lock.lock()
			defer { lock.unlock() }
			return _storage
		}
		set {
			lock.lock()
			defer { lock.unlock() }
			_storage = newValue
		}
	}

    mutating func delete(valueFor key: String) async throws {
        storage[key] = nil
    }

    mutating func deleteAll() async throws {
        storage.removeAll()
    }

    func get<T>(valueFor key: String) async throws -> T? where T: Decodable {
        guard let data = storage[key] else {
            return nil
        }
        return try decoder.decode(T.self, from: data)
    }

    mutating func set<T>(_ object: T, for key: String) async throws where T: Encodable {
        let data = try encoder.encode(object)
        storage[key] = data
    }
}
