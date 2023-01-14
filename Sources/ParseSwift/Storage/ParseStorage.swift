//
//  ParseStorage.swift
//  
//
//  Created by Pranjal Satija on 7/19/20.
//

// MARK: ParseStorage
struct ParseStorage {
    public static var shared = ParseStorage()

    private var backingStore: ParsePrimitiveStorable!

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
}

// MARK: ParsePrimitiveStorable
extension ParseStorage: ParsePrimitiveStorable {

    public mutating func delete(valueFor key: String) throws {
        try requireBackingStore()
        return try backingStore.delete(valueFor: key)
    }

    public mutating func deleteAll() throws {
        try requireBackingStore()
        return try backingStore.deleteAll()
    }

    public func get<T>(valueFor key: String) throws -> T? where T: Decodable {
        try requireBackingStore()
        return try backingStore.get(valueFor: key)
    }

    public mutating func set<T>(_ object: T, for key: String) throws where T: Encodable {
        try requireBackingStore()
        return try backingStore.set(object, for: key)
    }

}
