//
//  KeychainStoreTests.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-09-25.
//  Copyright © 2020 Parse. All rights reserved.
//

#if !os(Linux) && !os(Android) && !os(Windows)
import Foundation
import XCTest
@testable import ParseSwift

class KeychainStoreTests: XCTestCase {
    var testStore: KeychainStore!
    override func setUp() async throws {
        try await super.setUp()
        guard let url = URL(string: "http://localhost:1337/parse") else {
            XCTFail("Should create valid URL")
            return
        }
        try await ParseSwift.initialize(applicationId: "applicationId",
                                        clientKey: "clientKey",
                                        primaryKey: "primaryKey",
                                        serverURL: url, testing: true)
        testStore = await KeychainStore(service: "test")
    }

    override func tearDown() async throws {
        try await super.tearDown()
        _ = await testStore.removeAllObjects()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try await KeychainStore.shared.deleteAll()
        try? await KeychainStore.objectiveC?.deleteAllObjectiveC()
        #endif
        try await ParseStorage.shared.deleteAll()
    }

    func testSetObject() async throws {
        let isSet = await testStore.set(object: "yarr", forKey: "blah")
        XCTAssertTrue(isSet, "Set should succeed")
    }

    func testGetObjectSubscript() async throws {
        let key = "yarrKey"
        let value = "yarrValue"
        _ = await testStore.set(object: value, forKey: key)
        guard let storedValue: String = await testStore.object(forKey: key) else {
            XCTFail("Should unwrap to String")
            return
        }
        XCTAssertEqual(storedValue, value, "Values should be equal after get")
    }

    func testGetObject() async throws {
        let key = "yarrKey"
        let value = "yarrValue"
        _ = await testStore.set(object: value, forKey: key)
        guard let storedValue: String = await testStore.object(forKey: key) else {
            XCTFail("Should unwrap to String")
            return
        }
        XCTAssertEqual(storedValue, value, "Values should be equal after get")
    }

    func testGetAnyCodableObject() async throws {
        let key = "yarrKey"
        let value: AnyCodable = "yarrValue"
        _ = await testStore.set(object: value, forKey: key)
        guard let storedValue: AnyCodable = await testStore.object(forKey: key) else {
            XCTFail("Should unwrap to AnyCodable")
            return
        }
        XCTAssertEqual(storedValue, value, "Values should be equal after get")
    }

    func testSetComplextObject() async throws {
        let complexObject: [AnyCodable] = [["key": "value"], "string2", 1234]
        _ = await testStore.set(object: complexObject, forKey: "complexObject")
        guard let retrievedObject: [AnyCodable] = try await testStore.get(valueFor: "complexObject") else {
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
        _ = await testStore.set(object: value, forKey: key)
        var retrievedObject: String? = try await testStore.get(valueFor: key)
        XCTAssertEqual(retrievedObject, value)
        _ = await testStore.removeObject(forKey: key)
        retrievedObject = try await testStore.get(valueFor: key)
        XCTAssertNil(retrievedObject, "There should be no value after removal")
    }

    func testRemoveAllObjects() async throws {
        let key = "key1"
        let value = "value1"
        let key2 = "key2"
        let value2 = "value2"
        let isSet1 = await testStore.set(object: value, forKey: key)
        let isSet2 = await testStore.set(object: value2, forKey: key2)
        XCTAssertTrue(isSet1)
        XCTAssertTrue(isSet2)
        var retrievedObject: String? = try await testStore.get(valueFor: key)
        XCTAssertEqual(retrievedObject, value)
        retrievedObject = try await testStore.get(valueFor: key2)
        XCTAssertEqual(retrievedObject, value2)
        _ = await testStore.removeAllObjects()
        retrievedObject = try await testStore.get(valueFor: key)
        XCTAssertNil(retrievedObject, "There should be no value after removal")
        retrievedObject = try await testStore.get(valueFor: key2)
        XCTAssertNil(retrievedObject, "There should be no value after removal")
    }

    func testQueryTemplate() async throws {
        let query = await KeychainStore.shared.getKeychainQueryTemplate()
        XCTAssertEqual(query.count, 2)
        let service = await KeychainStore.shared.service
        XCTAssertEqual(query[kSecAttrService as String] as? String, service)
        XCTAssertEqual(query[kSecClass as String] as? String, kSecClassGenericPassword as String)
    }

    func testQueryNoAccessGroup() async throws {
        let accessGroup = ParseKeychainAccessGroup()
        let query = await KeychainStore.shared.keychainQuery(forKey: "hello", accessGroup: accessGroup)
        XCTAssertEqual(query.count, 5)
        let service = await KeychainStore.shared.service
        XCTAssertEqual(query[kSecAttrService as String] as? String, service)
        XCTAssertEqual(query[kSecClass as String] as? String, kSecClassGenericPassword as String)
        XCTAssertEqual(query[kSecAttrAccount as String] as? String, "hello")
        XCTAssertEqual(query[kSecAttrSynchronizable as String] as? Bool, kCFBooleanFalse as? Bool)
        XCTAssertEqual(query[kSecAttrAccessible as String] as? String,
                       kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
    }

    func testQueryAccessGroupSyncableKeyTrue() async throws {
        let accessGroup = ParseKeychainAccessGroup(accessGroup: "world", isSyncingKeychainAcrossDevices: true)
        let query = await KeychainStore.shared.keychainQuery(forKey: "hello", accessGroup: accessGroup)
        XCTAssertEqual(query.count, 6)
        let service = await KeychainStore.shared.service
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
        let query = await KeychainStore.shared.keychainQuery(forKey: "hello", accessGroup: accessGroup)
        XCTAssertEqual(query.count, 6)
        let service = await KeychainStore.shared.service
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
        let query = await KeychainStore.shared.keychainQuery(forKey: key, accessGroup: accessGroup)
        XCTAssertEqual(query.count, 6)
        let service = await KeychainStore.shared.service
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
        let query = await KeychainStore.shared.keychainQuery(forKey: key, accessGroup: accessGroup)
        XCTAssertEqual(query.count, 6)
        let service = await KeychainStore.shared.service
        XCTAssertEqual(query[kSecAttrService as String] as? String, service)
        XCTAssertEqual(query[kSecClass as String] as? String, kSecClassGenericPassword as String)
        XCTAssertEqual(query[kSecAttrAccount as String] as? String, key)
        XCTAssertEqual(query[kSecAttrAccessGroup as String] as? String, "world")
        XCTAssertEqual(query[kSecAttrSynchronizable as String] as? Bool, kCFBooleanFalse as? Bool)
        XCTAssertEqual(query[kSecAttrAccessible as String] as? String,
                       kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
    }

    func testSetObjectiveC() async throws {
        await KeychainStore.createObjectiveC()
        // Set keychain the way objc sets keychain
        guard let objcParseKeychain = KeychainStore.objectiveC else {
            XCTFail("Should have unwrapped")
            return
        }
        let objcInstallationId = "helloWorld"
        _ = await objcParseKeychain.setObjectiveC(object: objcInstallationId, forKey: "installationId")

        guard let retrievedValue: String = await objcParseKeychain.objectObjectiveC(forKey: "installationId") else {
            XCTFail("Should have casted")
            return
        }
        XCTAssertEqual(retrievedValue, objcInstallationId)
        let newInstallationId: String? = nil
        _ = await objcParseKeychain.setObjectiveC(object: newInstallationId, forKey: "installationId")
        let retrievedValue2: String? = await objcParseKeychain.objectObjectiveC(forKey: "installationId")
        XCTAssertNil(retrievedValue2)
    }
}
#endif
