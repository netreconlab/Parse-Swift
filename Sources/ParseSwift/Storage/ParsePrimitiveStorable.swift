//
//  ParsePrimitiveStorable.swift
//
//
//  Created by Pranjal Satija on 7/19/20.
//

import Foundation

/**
 A store that supports key/value storage. It should be able
 to handle any object that conforms to encodable and decodable.
 */
public protocol ParsePrimitiveStorable: Actor {
    /// Delete an object from the store.
    /// - parameter key: The unique key value of the object.
    func delete(valueFor key: String) throws
    /// Delete all objects from the store.
    func deleteAll() throws
    /// Gets an object from the store based on its `key`.
    /// - parameter key: The unique key value of the object.
    func get<T: Decodable>(valueFor key: String) throws -> T?
    /// Stores an object in the store with a given `key`.
    /// - parameter object: The object to store.
    /// - parameter key: The unique key value of the object.
    func set<T: Encodable>(_ object: T, for key: String) throws
}

#if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)

// MARK: KeychainStore + ParsePrimitiveStorable
extension KeychainStore: ParsePrimitiveStorable {

    func delete(valueFor key: String) throws {
        if !removeObject(forKey: key) {
            throw ParseError(code: .objectNotFound, message: "Object for key \"\(key)\" not found in Keychain")
        }
    }

    func deleteAll() throws {
        if !removeAllObjects() {
            throw ParseError(code: .objectNotFound, message: "Could not delete all objects in Keychain")
        }
    }

    func get<T>(valueFor key: String) throws -> T? where T: Decodable {
        object(forKey: key)
    }

    func set<T>(_ object: T, for key: String) throws where T: Encodable {
        if !set(object: object, forKey: key) {
            throw ParseError(code: .otherCause,
                             message: "Could not save object: \(object) key \"\(key)\" in Keychain")
        }
    }

}

#endif
