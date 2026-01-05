//
//  KeychainStoreTests.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-09-25.
//  Copyright © 2020 Parse. All rights reserved.
//

#if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
import Foundation
import XCTest
@testable import ParseSwift

class KeychainStoreTests: XCTestCase, @unchecked Sendable {

	static let keychainServiceName = "test"

    override func setUp() async throws {
        try await super.setUp()
        guard let url = URL(string: "http://localhost:1337/parse") else {
            XCTFail("Should create valid URL")
            return
        }
        try await ParseSwift.initialize(
			applicationId: "applicationId",
			clientKey: "clientKey",
			primaryKey: "primaryKey",
			serverURL: url, testing: true
		)

    }

    override func tearDown() async throws {
        try await super.tearDown()
        #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        try KeychainStore.shared.deleteAll()
        try? KeychainStore.objectiveC?.deleteAllObjectiveC()
        #endif
        try await ParseStorage.shared.deleteAll()
    }

    func testSetObject() async throws {
		let testStore = KeychainStore(service: Self.keychainServiceName)
        let isSet = testStore.set(object: "yarr", forKey: "blah")
        XCTAssertTrue(isSet, "Set should succeed")
    }

    func testGetObjectSubscript() async throws {
        let key = "yarrKey"
        let value = "yarrValue"
		let testStore = KeychainStore(service: Self.keychainServiceName)
        _ = testStore.set(object: value, forKey: key)
        guard let storedValue: String = testStore.object(forKey: key) else {
            XCTFail("Should unwrap to String")
            return
        }
        XCTAssertEqual(storedValue, value, "Values should be equal after get")
    }

    func testGetObject() async throws {
        let key = "yarrKey"
        let value = "yarrValue"
		let testStore = KeychainStore(service: Self.keychainServiceName)
        _ = testStore.set(object: value, forKey: key)
        guard let storedValue: String = testStore.object(forKey: key) else {
            XCTFail("Should unwrap to String")
            return
        }
        XCTAssertEqual(storedValue, value, "Values should be equal after get")
    }

    func testGetAnyCodableObject() async throws {
        let key = "yarrKey"
        let value: AnyCodable = "yarrValue"
		let testStore = KeychainStore(service: Self.keychainServiceName)
        _ = testStore.set(object: value, forKey: key)
        guard let storedValue: AnyCodable = testStore.object(forKey: key) else {
            XCTFail("Should unwrap to AnyCodable")
            return
        }
        XCTAssertEqual(storedValue, value, "Values should be equal after get")
    }

    func testSetComplextObject() async throws {
        let complexObject: [AnyCodable] = [["key": "value"], "string2", 1234]
		let testStore = KeychainStore(service: Self.keychainServiceName)
        _ = testStore.set(object: complexObject, forKey: "complexObject")
        guard let retrievedObject: [AnyCodable] = try testStore.get(valueFor: "complexObject") else {
            return XCTFail("Should retrieve the object")
        }
        XCTAssertTrue(retrievedObject.count == 3)
        retrievedObject.enumerated().forEach { (offset, retrievedValue) in
            let value = complexObject[offset].value
            switch offset {
            case 0:
                guard let dict = value as? [String: String],
                    let retrievedDictionary = retrievedValue.value as? [String: String] else {
                        return XCTFail("Should be both dictionaries")
                }
                XCTAssertTrue(dict == retrievedDictionary)
            case 1:
                guard let string = value as? String,
                    let retrievedString = retrievedValue.value as? String else {
                        return XCTFail("Should be both strings")
                }
                XCTAssertTrue(string == retrievedString)
            case 2:
                guard let int = value as? Int,
                    let retrievedInt = retrievedValue.value as? Int else {
                        return XCTFail("Should be both ints")
                }
                XCTAssertTrue(int == retrievedInt)
            default: break
            }
        }
    }

    func testRemoveObject() async throws {
        let key = "key1"
        let value = "value1"
		let testStore = KeychainStore(service: Self.keychainServiceName)
        _ = testStore.set(object: value, forKey: key)
        var retrievedObject: String? = try testStore.get(valueFor: key)
        XCTAssertEqual(retrievedObject, value)
        _ = testStore.removeObject(forKey: key)
        retrievedObject = try testStore.get(valueFor: key)
        XCTAssertNil(retrievedObject, "There should be no value after removal")
    }

    func testRemoveAllObjects() async throws {
        let key = "key1"
        let value = "value1"
        let key2 = "key2"
        let value2 = "value2"
		let testStore = KeychainStore(service: Self.keychainServiceName)
        let isSet1 = testStore.set(object: value, forKey: key)
        let isSet2 = testStore.set(object: value2, forKey: key2)
        XCTAssertTrue(isSet1)
        XCTAssertTrue(isSet2)
        var retrievedObject: String? = try testStore.get(valueFor: key)
        XCTAssertEqual(retrievedObject, value)
        retrievedObject = try testStore.get(valueFor: key2)
        XCTAssertEqual(retrievedObject, value2)
        _ = testStore.removeAllObjects()
        retrievedObject = try testStore.get(valueFor: key)
        XCTAssertNil(retrievedObject, "There should be no value after removal")
        retrievedObject = try testStore.get(valueFor: key2)
        XCTAssertNil(retrievedObject, "There should be no value after removal")
    }

    func testQueryTemplate() async throws {
        let query = KeychainStore.shared.getKeychainQueryTemplate()
        XCTAssertEqual(query.count, 2)
        let service = KeychainStore.shared.service
        XCTAssertEqual(query[kSecAttrService as String] as? String, service)
        XCTAssertEqual(query[kSecClass as String] as? String, kSecClassGenericPassword as String)
    }

    func testQueryNoAccessGroup() async throws {
        let accessGroup = ParseKeychainAccessGroup()
        let query = KeychainStore.shared.keychainQuery(forKey: "hello", accessGroup: accessGroup)
        XCTAssertEqual(query.count, 5)
        let service = KeychainStore.shared.service
        XCTAssertEqual(query[kSecAttrService as String] as? String, service)
        XCTAssertEqual(query[kSecClass as String] as? String, kSecClassGenericPassword as String)
        XCTAssertEqual(query[kSecAttrAccount as String] as? String, "hello")
        XCTAssertEqual(query[kSecAttrSynchronizable as String] as? Bool, kCFBooleanFalse as? Bool)
        XCTAssertEqual(query[kSecAttrAccessible as String] as? String,
                       kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
    }

    func testQueryAccessGroupSyncableKeyTrue() async throws {
        let accessGroup = ParseKeychainAccessGroup(accessGroup: "world", isSyncingKeychainAcrossDevices: true)
        let query = KeychainStore.shared.keychainQuery(forKey: "hello", accessGroup: accessGroup)
        XCTAssertEqual(query.count, 6)
        let service = KeychainStore.shared.service
        XCTAssertEqual(query[kSecAttrService as String] as? String, service)
        XCTAssertEqual(query[kSecClass as String] as? String, kSecClassGenericPassword as String)
        XCTAssertEqual(query[kSecAttrAccount as String] as? String, "hello")
        XCTAssertEqual(query[kSecAttrAccessGroup as String] as? String, "world")
        XCTAssertEqual(query[kSecAttrSynchronizable as String] as? Bool, kCFBooleanTrue as? Bool)
        XCTAssertEqual(query[kSecAttrAccessible as String] as? String,
                       kSecAttrAccessibleAfterFirstUnlock as String)
    }

    func testQueryAccessGroupSyncableKeyFalse() async throws {
        let accessGroup = ParseKeychainAccessGroup(accessGroup: "world", isSyncingKeychainAcrossDevices: false)
        let query = KeychainStore.shared.keychainQuery(forKey: "hello", accessGroup: accessGroup)
        XCTAssertEqual(query.count, 6)
        let service = KeychainStore.shared.service
        XCTAssertEqual(query[kSecAttrService as String] as? String, service)
        XCTAssertEqual(query[kSecClass as String] as? String, kSecClassGenericPassword as String)
        XCTAssertEqual(query[kSecAttrAccount as String] as? String, "hello")
        XCTAssertEqual(query[kSecAttrAccessGroup as String] as? String, "world")
        XCTAssertEqual(query[kSecAttrSynchronizable as String] as? Bool, kCFBooleanFalse as? Bool)
        XCTAssertEqual(query[kSecAttrAccessible as String] as? String,
                       kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
    }

    func testQueryAccessGroupNoSyncableKeyTrue() async throws {
        let key = ParseStorage.Keys.currentInstallation
        let accessGroup = ParseKeychainAccessGroup(accessGroup: "world", isSyncingKeychainAcrossDevices: true)
        let query = KeychainStore.shared.keychainQuery(forKey: key, accessGroup: accessGroup)
        XCTAssertEqual(query.count, 6)
        let service = KeychainStore.shared.service
        XCTAssertEqual(query[kSecAttrService as String] as? String, service)
        XCTAssertEqual(query[kSecClass as String] as? String, kSecClassGenericPassword as String)
        XCTAssertEqual(query[kSecAttrAccount as String] as? String, key)
        XCTAssertEqual(query[kSecAttrAccessGroup as String] as? String, "world")
        XCTAssertEqual(query[kSecAttrSynchronizable as String] as? Bool, kCFBooleanFalse as? Bool)
        XCTAssertEqual(query[kSecAttrAccessible as String] as? String,
                       kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
    }

    func testQueryAccessGroupNoSyncableKeyFalse() async throws {
        let key = ParseStorage.Keys.currentInstallation
        let accessGroup = ParseKeychainAccessGroup(accessGroup: "world", isSyncingKeychainAcrossDevices: false)
        let query = KeychainStore.shared.keychainQuery(forKey: key, accessGroup: accessGroup)
        XCTAssertEqual(query.count, 6)
        let service = KeychainStore.shared.service
        XCTAssertEqual(query[kSecAttrService as String] as? String, service)
        XCTAssertEqual(query[kSecClass as String] as? String, kSecClassGenericPassword as String)
        XCTAssertEqual(query[kSecAttrAccount as String] as? String, key)
        XCTAssertEqual(query[kSecAttrAccessGroup as String] as? String, "world")
        XCTAssertEqual(query[kSecAttrSynchronizable as String] as? Bool, kCFBooleanFalse as? Bool)
        XCTAssertEqual(query[kSecAttrAccessible as String] as? String,
                       kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
    }

    func testSetObjectiveC() async throws {
        KeychainStore.createObjectiveC()
        // Set keychain the way objc sets keychain
        guard let objcParseKeychain = KeychainStore.objectiveC else {
            XCTFail("Should have unwrapped")
            return
        }
        let objcInstallationId = "helloWorld"
        _ = objcParseKeychain.setObjectiveC(object: objcInstallationId, forKey: "installationId")

        guard let retrievedValue: String = objcParseKeychain.objectObjectiveC(forKey: "installationId") else {
            XCTFail("Should have casted")
            return
        }
        XCTAssertEqual(retrievedValue, objcInstallationId)
        let newInstallationId: String? = nil
        _ = objcParseKeychain.setObjectiveC(object: newInstallationId, forKey: "installationId")
        let retrievedValue2: String? = objcParseKeychain.objectObjectiveC(forKey: "installationId")
        XCTAssertNil(retrievedValue2)
    }
}
#endif
