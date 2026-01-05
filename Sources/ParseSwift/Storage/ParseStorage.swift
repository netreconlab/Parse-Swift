//
//  ParseStorage.swift
//  
//
//  Created by Pranjal Satija on 7/19/20.
//

// MARK: ParseStorage
struct ParseStorage {
	nonisolated(unsafe) static var shared = ParseStorage()

    var backingStore: ParsePrimitiveStorable!

	mutating func use(_ store: ParsePrimitiveStorable) {
        self.backingStore = store
    }

    private func requireBackingStore() throws {
        guard backingStore != nil else {
            throw ParseError(code: .otherCause,
                             message: """
                You cannot use ParseStorage without a backing store.
                An in-memory store is being used as a fallback.
            """)
        }
    }

    enum Keys {
        static let currentUser = "_currentUser"
        static let currentInstallation = "_currentInstallation"
        static let currentConfig = "_currentConfig"
        static let defaultACL = "_defaultACL"
        static let currentVersion = "_currentVersion"
        static let currentAccessGroup = "_currentAccessGroup"
    }

    mutating func setBackingStoreToNil() {
        backingStore = nil
    }
}

// MARK: Act as a proxy for ParsePrimitiveStorable
extension ParseStorage {

    mutating func delete(valueFor key: String) async throws {
        try requireBackingStore()
        return try await backingStore.delete(valueFor: key)
    }

	mutating func deleteAll() async throws {
        try requireBackingStore()
        return try await backingStore.deleteAll()
    }

    func get<T>(valueFor key: String) async throws -> T? where T: Decodable & Sendable {
        try requireBackingStore()
        return try await backingStore.get(valueFor: key)
    }

	mutating func set<T>(_ object: T, for key: String) async throws where T: Encodable & Sendable {
        try requireBackingStore()
        return try await backingStore.set(object, for: key)
    }
}
