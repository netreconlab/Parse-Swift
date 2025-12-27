//
//  KeychainStore.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-09-25.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation
#if canImport(Security)
import Security
#endif

#if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)

// swiftlint:disable type_body_length

/**
 KeychainStore is UserDefaults-like wrapper on top of Keychain.
 It supports any object, with Coding support. All objects are available after the
 first device unlock and are not backed up.
 */
actor KeychainStore: SecureStorable {

    let service: String
    static var objectiveCService: String {
        guard let identifier = Bundle.main.bundleIdentifier else {
            return ""
        }
        return "\(identifier).com.parse.sdk"
    }
    static var shared: KeychainStore!
    static var objectiveC: KeychainStore!
    // This Keychain was used by SDK <= 1.9.7
    static var old: KeychainStore!

    init(service: String? = nil) async {
        var keychainService = ".parseSwift.sdk"
        if let service = service {
            keychainService = service
        } else if let identifier = Bundle.main.bundleIdentifier {
            keychainService = "\(identifier)\(keychainService)"
        } else {
            keychainService = "com\(keychainService)"
        }
        self.service = keychainService
    }

    static func createShared() async {
        if KeychainStore.shared == nil {
            KeychainStore.shared = await KeychainStore()
        }
    }

    static func createObjectiveC() async {
        if KeychainStore.objectiveC == nil {
            KeychainStore.objectiveC = await KeychainStore(service: objectiveCService)
        }
    }

    static func createOld() async {
        if KeychainStore.old == nil {
            KeychainStore.old = await KeychainStore(service: "shared")
        }
    }

    func getKeychainQueryTemplate() -> [String: Any] {
        var query = [String: Any]()
        if !service.isEmpty {
            query[kSecAttrService as String] = service
        }
        query[kSecClass as String] = kSecClassGenericPassword as String
        return query
    }

    func getObjectiveCKeychainQueryTemplate() -> [String: Any] {
        var query = [String: Any]()
        if !Self.objectiveCService.isEmpty {
            query[kSecAttrService as String] = Self.objectiveCService
        }
        query[kSecClass as String] = kSecClassGenericPassword as String
        return query
    }

    func copy(_ keychain: KeychainStore,
              oldAccessGroup: ParseKeychainAccessGroup,
              newAccessGroup: ParseKeychainAccessGroup) async throws {
        if let user = await keychain.data(forKey: ParseStorage.Keys.currentUser,
                                          accessGroup: oldAccessGroup) {
            try set(user,
                    forKey: ParseStorage.Keys.currentUser,
                    oldAccessGroup: oldAccessGroup,
                    newAccessGroup: newAccessGroup)
        }
        if let installation = await keychain.data(forKey: ParseStorage.Keys.currentInstallation,
                                                  accessGroup: oldAccessGroup) {
            try set(installation,
                    forKey: ParseStorage.Keys.currentInstallation,
                    oldAccessGroup: oldAccessGroup,
                    newAccessGroup: newAccessGroup)
        }
        if let version = await keychain.data(forKey: ParseStorage.Keys.currentVersion,
                                             accessGroup: oldAccessGroup) {
            try set(version,
                    forKey: ParseStorage.Keys.currentVersion,
                    oldAccessGroup: oldAccessGroup,
                    newAccessGroup: newAccessGroup)
        }
        if let config = await keychain.data(forKey: ParseStorage.Keys.currentConfig,
                                            accessGroup: oldAccessGroup) {
            try set(config,
                    forKey: ParseStorage.Keys.currentConfig,
                    oldAccessGroup: oldAccessGroup,
                    newAccessGroup: newAccessGroup)
        }
        if let acl = await keychain.data(forKey: ParseStorage.Keys.defaultACL,
                                         accessGroup: oldAccessGroup) {
            try set(acl,
                    forKey: ParseStorage.Keys.defaultACL,
                    oldAccessGroup: oldAccessGroup,
                    newAccessGroup: newAccessGroup)
        }
        if let keychainAccessGroup = await keychain.data(forKey: ParseStorage.Keys.currentAccessGroup,
                                                         accessGroup: oldAccessGroup) {
            try set(keychainAccessGroup,
                    forKey: ParseStorage.Keys.currentAccessGroup,
                    oldAccessGroup: oldAccessGroup,
                    newAccessGroup: newAccessGroup)
        }
    }

    func isSyncableKey(_ key: String) -> Bool {
        key != ParseStorage.Keys.currentInstallation &&
        key != ParseStorage.Keys.currentVersion &&
        key != ParseStorage.Keys.currentAccessGroup
    }

    func keychainQuery(forKey key: String,
                       useObjectiveCKeychain: Bool = false,
                       accessGroup: ParseKeychainAccessGroup) -> [String: Any] {
        if !useObjectiveCKeychain {
            var query: [String: Any] = getKeychainQueryTemplate()
            query[kSecAttrAccount as String] = key
            if let keychainAccessGroup = accessGroup.accessGroup {
                query[kSecAttrAccessGroup as String] = keychainAccessGroup
                if accessGroup.isSyncingKeychainAcrossDevices && isSyncableKey(key) {
                    query[kSecAttrSynchronizable as String] = kCFBooleanTrue
                    query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock as String
                } else {
                    query[kSecAttrSynchronizable as String] = kCFBooleanFalse
                    query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
                }
            } else {
                query[kSecAttrSynchronizable as String] = kCFBooleanFalse
                query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
            }
            #if os(macOS)
            if Parse.configuration.isUsingDataProtectionKeychain {
                query[kSecUseDataProtectionKeychain as String] = kCFBooleanTrue
            }
            #endif
            return query
        } else {
            var query: [String: Any] = getKeychainQueryTemplate()
            query[kSecAttrAccount as String] = key
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock as String
            return query
        }
    }

    func data(forKey key: String,
              useObjectiveCKeychain: Bool = false,
              accessGroup: ParseKeychainAccessGroup) -> Data? {
        var query: [String: Any] = keychainQuery(forKey: key,
                                                 useObjectiveCKeychain: useObjectiveCKeychain,
                                                 accessGroup: accessGroup)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = kCFBooleanTrue

        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }

        guard status == errSecSuccess,
            let data = result as? Data else {
            return nil
        }

        return data
    }

    private func set(_ data: Data,
                     forKey key: String,
                     useObjectiveCKeychain: Bool = false,
                     oldAccessGroup: ParseKeychainAccessGroup,
                     newAccessGroup: ParseKeychainAccessGroup) throws {
        var query = keychainQuery(forKey: key,
                                  accessGroup: oldAccessGroup)
        var update: [String: Any] = [
            kSecValueData as String: data
        ]

        if !useObjectiveCKeychain {
            if let newKeychainAccessGroup = newAccessGroup.accessGroup {
                update[kSecAttrAccessGroup as String] = newKeychainAccessGroup
                if newAccessGroup.isSyncingKeychainAcrossDevices && isSyncableKey(key) {
                    update[kSecAttrSynchronizable as String] = kCFBooleanTrue
                    update[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock as String
                } else {
                    update[kSecAttrSynchronizable as String] = kCFBooleanFalse
                    update[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
                }
            } else {
                query.removeValue(forKey: kSecAttrAccessGroup as String)
                update[kSecAttrSynchronizable as String] = kCFBooleanFalse
                update[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
            }
        } else {
            update[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock as String
        }

        let mergedQuery = query.merging(update) { (_, otherValue) -> Any in otherValue }
        guard self.data(forKey: key,
                        accessGroup: newAccessGroup) != nil else {
            let status = SecItemAdd(mergedQuery as CFDictionary, nil)
            guard status == errSecSuccess else {
                throw ParseError(code: .otherCause,
                                 message: "Could not save to Keychain, OSStatus: \(status)")
            }
            return
        }

        var updateStatus = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if updateStatus == errSecDuplicateItem {
            if SecItemDelete(mergedQuery as CFDictionary) == errSecSuccess {
                updateStatus = SecItemAdd(mergedQuery as CFDictionary, nil)
            }
        }
        guard updateStatus == errSecSuccess else {
            throw ParseError(code: .otherCause,
                             message: "Could not save to Keychain, OSStatus: \(updateStatus)")
        }
    }

    private func removeObject(forKey key: String,
                              useObjectiveCKeychain: Bool = false,
                              accessGroup: ParseKeychainAccessGroup) -> Bool {
        let query = keychainQuery(forKey: key,
                                  useObjectiveCKeychain: useObjectiveCKeychain,
                                  accessGroup: accessGroup) as CFDictionary
        return SecItemDelete(query) == errSecSuccess
    }

    func removeOldObjects(accessGroup: ParseKeychainAccessGroup) -> Bool {
        var query = getKeychainQueryTemplate()
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitAll

        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        if status != errSecSuccess { return true }

        guard let results = result as? [[String: Any]] else { return false }

        for item in results {
            guard let key = item[kSecAttrAccount as String] as? String,
                  isSyncableKey(key) else {
                continue
            }
            guard self.removeObject(forKey: key,
                                    accessGroup: accessGroup) else {
                return false
            }
        }
        return true
    }

    func removeAllObjects(useObjectiveCKeychain: Bool) -> Bool {
        var query = useObjectiveCKeychain ? getObjectiveCKeychainQueryTemplate() : getKeychainQueryTemplate()
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitAll

        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        if status != errSecSuccess { return true }

        guard let results = result as? [[String: Any]] else { return false }

        for item in results {
            guard let key = item[kSecAttrAccount as String] as? String else {
                continue
            }
            let removedDefaultObject = self.removeObject(forKey: key,
                                                         useObjectiveCKeychain: useObjectiveCKeychain,
                                                         accessGroup: Parse.configuration.keychainAccessGroup)
            if !useObjectiveCKeychain {
                var mutatedKeychainAccessGroup = Parse.configuration.keychainAccessGroup
                mutatedKeychainAccessGroup.isSyncingKeychainAcrossDevices.toggle()
                let removedToggledObject = self.removeObject(forKey: key,
                                                             accessGroup: mutatedKeychainAccessGroup)
                mutatedKeychainAccessGroup.accessGroup = nil
                let removedNoAccessGroupObject = self.removeObject(forKey: key,
                                                                   accessGroup: mutatedKeychainAccessGroup)
                if !(
                    removedDefaultObject ||
                    removedToggledObject ||
                    removedNoAccessGroupObject
                ) {
                    return false
                }
            }
        }
        return true
    }
}

// MARK: SecureStorage
extension KeychainStore {
    func object<T>(forKey key: String) -> T? where T: Decodable {
        guard let data = self.data(forKey: key,
                                   accessGroup: Parse.configuration.keychainAccessGroup) else {
            return nil
        }
        do {
            return try ParseCoding.jsonDecoder().decode(T.self, from: data)
        } catch {
            return nil
        }
    }

    func set<T>(object: T?, forKey key: String) -> Bool where T: Encodable {
        guard let object = object else {
            return removeObject(forKey: key)
        }
        do {
            let data = try ParseCoding.jsonEncoder().encode(object)
            try set(data,
                    forKey: key,
                    oldAccessGroup: Parse.configuration.keychainAccessGroup,
                    newAccessGroup: Parse.configuration.keychainAccessGroup)
            return true
        } catch {
            return false
        }
    }

    subscript<T>(key: String) -> T? where T: Codable {
        get {
            object(forKey: key)
        }
        set (object) {
            _ = set(object: object, forKey: key)
        }
    }

    func removeObject(forKey key: String) -> Bool {
        removeObject(forKey: key,
                     accessGroup: Parse.configuration.keychainAccessGroup)
    }

    func removeAllObjects() -> Bool {
        removeAllObjects(useObjectiveCKeychain: false)
    }
}

// MARK: Objective-C SDK Keychain
extension KeychainStore {
    func objectObjectiveC<T>(forKey key: String) -> T? where T: Decodable {
        guard let data = self.data(forKey: key,
                                   useObjectiveCKeychain: true,
                                   accessGroup: Parse.configuration.keychainAccessGroup) else {
            return nil
        }
        do {
            do {
                return try NSKeyedUnarchiver.unarchivedObject(ofClass: NSString.self, from: data) as? T
            } catch {
                return try NSKeyedUnarchiver.unarchivedObject(ofClass: NSDictionary.self, from: data) as? T
            }
        } catch {
            return nil
        }
    }

    func removeObjectObjectiveC(forKey key: String) -> Bool {
        removeObject(forKey: key,
                     useObjectiveCKeychain: true,
                     accessGroup: Parse.configuration.keychainAccessGroup)
    }

    func setObjectiveC<T>(object: T?, forKey key: String) -> Bool where T: Encodable {
        guard let object = object else {
            return removeObjectObjectiveC(forKey: key)
        }
        do {
            let data: Data!
            if let stringObject = object as? String {
                data = try NSKeyedArchiver.archivedData(withRootObject: stringObject as NSString,
                                                        requiringSecureCoding: false)
            } else if let dictionaryObject = object as? [String: String] {
                data = try NSKeyedArchiver.archivedData(withRootObject: dictionaryObject as NSDictionary,
                                                        requiringSecureCoding: false)
            } else {
                data = try NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: false)
            }
            try set(data,
                    forKey: key,
                    useObjectiveCKeychain: true,
                    oldAccessGroup: Parse.configuration.keychainAccessGroup,
                    newAccessGroup: Parse.configuration.keychainAccessGroup)
            return true
        } catch {
            return false
        }
    }

    func deleteAllObjectiveC() throws {
        if !removeAllObjects(useObjectiveCKeychain: true) {
            throw ParseError(code: .objectNotFound, message: "Could not delete all objects in Keychain")
        }
    }
}

#endif
