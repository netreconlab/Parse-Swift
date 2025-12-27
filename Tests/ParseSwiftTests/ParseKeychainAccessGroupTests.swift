//
//  ParseKeychainAccessGroupTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/3/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

#if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
import Foundation
import XCTest
@testable import ParseSwift

// swiftlint:disable line_length unused_optional_binding function_body_length type_body_length

class ParseKeychainAccessGroupTests: XCTestCase {

    struct User: ParseUser {

        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        // These are required by ParseUser
        var username: String?
        var email: String?
        var emailVerified: Bool?
        var password: String?
        var authData: [String: [String: String]?]?

        // Your custom keys
        var customKey: String?
    }

    struct LoginSignupResponse: ParseUser {

        var objectId: String?
        var createdAt: Date?
        var sessionToken: String
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        // These are required by ParseUser
        var username: String?
        var email: String?
        var emailVerified: Bool?
        var password: String?
        var authData: [String: [String: String]?]?

        // Your custom keys
        var customKey: String?

        init() {
            let date = Date()
            self.createdAt = date
            self.updatedAt = date
            self.objectId = "yarr"
            self.ACL = nil
            self.customKey = "blah"
            self.sessionToken = "myToken"
            self.username = "hello10"
            self.email = "hello@parse.com"
        }
    }

    struct Installation: ParseInstallation {
        var installationId: String?
        var deviceType: String?
        var deviceToken: String?
        var badge: Int?
        var timeZone: String?
        var channels: [String]?
        var appName: String?
        var appIdentifier: String?
        var appVersion: String?
        var parseVersion: String?
        var localeIdentifier: String?
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?
        var customKey: String?

        //: Implement your own version of merge
        func merge(with object: Self) throws -> Self {
            var updated = try mergeParse(with: object)
            if updated.shouldRestoreKey(\.customKey,
                                         original: object) {
                updated.customKey = object.customKey
            }
            return updated
        }
    }

    struct Config: ParseConfig {
        var welcomeMessage: String?
        var winningNumber: Int?
    }

    let group = "TEAM.com.parse.parseswift"
    let keychainAccessGroup = ParseKeychainAccessGroup(accessGroup: "TEAM.com.parse.parseswift",
                                                       isSyncingKeychainAcrossDevices: false)
    let keychainAccessGroupSync = ParseKeychainAccessGroup(accessGroup: "TEAM.com.parse.parseswift",
                                                           isSyncingKeychainAcrossDevices: true)
    let helloKeychainAccessGroup = ParseKeychainAccessGroup(accessGroup: "hello",
                                                            isSyncingKeychainAcrossDevices: false)
    let noKeychainAccessGroup = ParseKeychainAccessGroup()

    override func setUp() async throws {
        try await super.setUp()
        guard let url = URL(string: "http://localhost:1337/parse") else {
            XCTFail("Should create valid URL")
            return
        }
        try await ParseSwift.initialize(applicationId: "applicationId",
                                        clientKey: "clientKey",
                                        primaryKey: "primaryKey",
                                        serverURL: url,
                                        testing: true)
    }

    override func tearDown() async throws {
        try await super.tearDown()
        #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        _ = await KeychainStore.shared.removeAllObjects()
        #endif
        try await ParseStorage.shared.deleteAll()
    }

    func userLogin() async throws {
        let loginResponse = LoginSignupResponse()
        let loginUserName = "hello10"
        let loginPassword = "world"

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        _ = try await User.login(username: loginUserName, password: loginPassword)
        MockURLProtocol.removeAll()
    }

    func testKeychainAccessGroupCreatedOnServerInit() async throws {
        var currentAccessGroup = try await ParseKeychainAccessGroup.current()
        XCTAssertNotNil(currentAccessGroup)
        XCTAssertNil(ParseSwift.configuration.keychainAccessGroup.accessGroup)
        XCTAssertFalse(ParseSwift.configuration.keychainAccessGroup.isSyncingKeychainAcrossDevices)
        currentAccessGroup = try await ParseKeychainAccessGroup.current()
        XCTAssertEqual(ParseSwift.configuration.keychainAccessGroup, currentAccessGroup)
    }

    func testUpdateStorageAccessGroup() async throws {
        var currentAccessGroup = try await ParseKeychainAccessGroup.current()
        XCTAssertEqual(ParseSwift.configuration.keychainAccessGroup, currentAccessGroup)
        await ParseKeychainAccessGroup.setCurrent(keychainAccessGroupSync)
        currentAccessGroup = try await ParseKeychainAccessGroup.current()
        XCTAssertEqual(ParseSwift.configuration.keychainAccessGroup, currentAccessGroup)
        await ParseKeychainAccessGroup.setCurrent(nil)
        currentAccessGroup = try await ParseKeychainAccessGroup.current()
        XCTAssertEqual(currentAccessGroup, noKeychainAccessGroup)
        XCTAssertEqual(ParseSwift.configuration.keychainAccessGroup, noKeychainAccessGroup)
        await ParseKeychainAccessGroup.setCurrent(keychainAccessGroupSync)
        currentAccessGroup = try await ParseKeychainAccessGroup.current()
        XCTAssertEqual(ParseSwift.configuration.keychainAccessGroup, currentAccessGroup)
    }

    func testCanGetKeychainAccessGroupFromKeychain() async throws {
        let currentAccessGroup = try await ParseKeychainAccessGroup.current()
        try await ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentAccessGroup)
        let updatedAccessGroup = try await ParseKeychainAccessGroup.current()
        XCTAssertEqual(currentAccessGroup, updatedAccessGroup)
    }

    func testDeleteKeychainAccessGroup() async throws {
        var currentGroup = try await ParseKeychainAccessGroup.current()
        XCTAssertEqual(currentGroup, noKeychainAccessGroup)
        XCTAssertEqual(ParseSwift.configuration.keychainAccessGroup, noKeychainAccessGroup)
        await ParseKeychainAccessGroup.deleteCurrentContainerFromStorage()
        XCTAssertEqual(ParseSwift.configuration.keychainAccessGroup, noKeychainAccessGroup)
        do {
            currentGroup = try await ParseKeychainAccessGroup.current()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.containedIn([.otherCause]))
        }
        await ParseKeychainAccessGroup.setCurrent(keychainAccessGroup)
        currentGroup = try await ParseKeychainAccessGroup.current()
        XCTAssertEqual(currentGroup, keychainAccessGroup)
        XCTAssertEqual(ParseSwift.configuration.keychainAccessGroup, keychainAccessGroup)
    }

    // swiftlint:disable:next cyclomatic_complexity
    func testCanCopyEntireKeychain() async throws {
        try await userLogin()
        await Config.setCurrent(.init(welcomeMessage: "yolo", winningNumber: 1))
        _ = try await ParseACL.setDefaultACL(ParseACL(), withAccessForCurrentUser: true)
        guard let user: CurrentUserContainer<User> =
                try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let installation: CurrentInstallationContainer<Installation> =
                try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let version: ParseVersion =
                try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentVersion) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let accessGroup: ParseKeychainAccessGroup =
                try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentAccessGroup) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let config: CurrentConfigContainer<Config> =
                try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let acl: DefaultACL =
                try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.defaultACL) else {
            XCTFail("Should have unwrapped")
            return
        }
        let otherKeychain = await KeychainStore(service: "other")
        try await otherKeychain.copy(KeychainStore.shared,
                                     oldAccessGroup: ParseSwift.configuration.keychainAccessGroup,
                                     newAccessGroup: ParseSwift.configuration.keychainAccessGroup)
        guard let otherUser: CurrentUserContainer<User> =
                try? await otherKeychain.get(valueFor: ParseStorage.Keys.currentUser) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let otherInstallation: CurrentInstallationContainer<Installation> =
                try? await otherKeychain.get(valueFor: ParseStorage.Keys.currentInstallation) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let otherVersion: ParseVersion =
                try? await otherKeychain.get(valueFor: ParseStorage.Keys.currentVersion) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let otherAccessGroup: ParseKeychainAccessGroup =
                try? await otherKeychain.get(valueFor: ParseStorage.Keys.currentAccessGroup) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let otherConfig: CurrentConfigContainer<Config> =
                try? await otherKeychain.get(valueFor: ParseStorage.Keys.currentConfig) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let otherAcl: DefaultACL =
                try? await otherKeychain.get(valueFor: ParseStorage.Keys.defaultACL) else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertEqual(user, otherUser)
        XCTAssertEqual(installation, otherInstallation)
        XCTAssertEqual(version, otherVersion)
        XCTAssertEqual(accessGroup, otherAccessGroup)
        XCTAssertEqual(config, otherConfig)
        XCTAssertEqual(acl, otherAcl)
    }

    // swiftlint:disable:next cyclomatic_complexity
    func testRemoveOldObjectsFromKeychain() async throws {
        try await userLogin()
        await Config.setCurrent(.init(welcomeMessage: "yolo", winningNumber: 1))
        _ = try await ParseACL.setDefaultACL(ParseACL(), withAccessForCurrentUser: true)

        guard let _: CurrentUserContainer<User> =
                try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let _: CurrentInstallationContainer<Installation> =
                try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let _: ParseVersion =
                try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentVersion) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let _: ParseKeychainAccessGroup =
                try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentAccessGroup) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let _: CurrentConfigContainer<Config> =
                try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let _: DefaultACL =
                try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.defaultACL) else {
            XCTFail("Should have unwrapped")
            return
        }
        let deleted = await KeychainStore.shared.removeOldObjects(accessGroup: ParseSwift.configuration.keychainAccessGroup)
        XCTAssertTrue(deleted)
        if let _: CurrentUserContainer<User> =
                try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser) {
            XCTFail("Should be nil")
        }
        if let _: CurrentConfigContainer<Config> =
                try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig) {
            XCTFail("Should be nil")
        }
        if let _: DefaultACL =
                try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.defaultACL) {
            XCTFail("Should be nil")
        }
        guard let _: CurrentInstallationContainer<Installation> =
                try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let _: ParseVersion =
                try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentVersion) else {
            XCTFail("Should have unwrapped")
            return
        }
        guard let _: ParseKeychainAccessGroup =
                try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentAccessGroup) else {
            XCTFail("Should have unwrapped")
            return
        }
    }

    func testNoUserNoAccessGroupNoSync() async throws {
        var data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                                   accessGroup: noKeychainAccessGroup)
        XCTAssertNil(data)
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                               accessGroup: noKeychainAccessGroup)
        XCTAssertNotNil(data)
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                               accessGroup: noKeychainAccessGroup)
        XCTAssertNotNil(data)
    }

    func testUserNoAccessGroupNoSync() async throws {
        try await userLogin()
        var data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                                   accessGroup: noKeychainAccessGroup)
        XCTAssertNotNil(data)
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                               accessGroup: noKeychainAccessGroup)
        XCTAssertNotNil(data)
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                               accessGroup: noKeychainAccessGroup)
        XCTAssertNotNil(data)
    }

    func testSetAccessGroupWithNoSync() async throws {
        try await userLogin()
        var data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                                   accessGroup: noKeychainAccessGroup)
        XCTAssertNotNil(data)
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                               accessGroup: noKeychainAccessGroup)
        XCTAssertNotNil(data)
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                               accessGroup: noKeychainAccessGroup)
        XCTAssertNotNil(data)

        #if !os(macOS)
        do {
            try await ParseSwift.setAccessGroup(group, synchronizeAcrossDevices: false)
            XCTFail("Should have thrown error due to entitlements")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted to ParseError")
                return
            }
            XCTAssertTrue(parseError.message.contains("-34018"))
        }
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                               accessGroup: helloKeychainAccessGroup)
        XCTAssertNil(data)
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                               accessGroup: helloKeychainAccessGroup)
        XCTAssertNil(data)
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                               accessGroup: helloKeychainAccessGroup)
        XCTAssertNil(data)
        #endif
        // Since error was thrown, original Keychain should be left intact
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                               accessGroup: noKeychainAccessGroup)
        XCTAssertNotNil(data)
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                               accessGroup: noKeychainAccessGroup)
        XCTAssertNotNil(data)
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                               accessGroup: noKeychainAccessGroup)
        XCTAssertNotNil(data)
    }

    func testSetAccessGroupWithSync() async throws {
        try await userLogin()
        var data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                                   accessGroup: noKeychainAccessGroup)
        XCTAssertNotNil(data)
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                               accessGroup: noKeychainAccessGroup)
        XCTAssertNotNil(data)
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                               accessGroup: noKeychainAccessGroup)
        XCTAssertNotNil(data)

        do {
            try await ParseSwift.setAccessGroup(group, synchronizeAcrossDevices: true)
            XCTFail("Should have thrown error due to entitlements")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted to ParseError")
                return
            }
            XCTAssertTrue(parseError.message.contains("-34018"))
        }
        #if !os(macOS)
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                               accessGroup: helloKeychainAccessGroup)
        XCTAssertNil(data)
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                               accessGroup: helloKeychainAccessGroup)
        XCTAssertNil(data)
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                               accessGroup: helloKeychainAccessGroup)
        #endif
        // Since error was thrown, original Keychain should be left intact
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                               accessGroup: noKeychainAccessGroup)
        XCTAssertNotNil(data)
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                               accessGroup: noKeychainAccessGroup)
        XCTAssertNotNil(data)
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                               accessGroup: noKeychainAccessGroup)
        XCTAssertNotNil(data)
    }

    func testSetAccessNilGroupWithSync() async throws {
        try await userLogin()
        var data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                                   accessGroup: noKeychainAccessGroup)
        XCTAssertNotNil(data)
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                               accessGroup: noKeychainAccessGroup)
        XCTAssertNotNil(data)
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                               accessGroup: noKeychainAccessGroup)
        XCTAssertNotNil(data)

        do {
            try await ParseSwift.setAccessGroup(nil, synchronizeAcrossDevices: true)
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted to ParseError")
                return
            }
            XCTAssertTrue(parseError.message.contains("must be set to a valid string"))
        }
        #if !os(macOS)
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                               accessGroup: helloKeychainAccessGroup)
        XCTAssertNil(data)
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                               accessGroup: helloKeychainAccessGroup)
        XCTAssertNil(data)
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                               accessGroup: helloKeychainAccessGroup)
        #endif
        // Since error was thrown, original Keychain should be left intact
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentUser,
                                               accessGroup: noKeychainAccessGroup)
        XCTAssertNotNil(data)
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentInstallation,
                                               accessGroup: noKeychainAccessGroup)
        XCTAssertNotNil(data)
        data = await KeychainStore.shared.data(forKey: ParseStorage.Keys.currentVersion,
                                               accessGroup: noKeychainAccessGroup)
        XCTAssertNotNil(data)
    }

    func testSetAccessGroupWhenNotInit() async throws {
        try await ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentAccessGroup)
        try await KeychainStore.shared.delete(valueFor: ParseStorage.Keys.currentAccessGroup)
        do {
            try await ParseSwift.setAccessGroup("hello", synchronizeAcrossDevices: true)
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted to ParseError")
                return
            }
            XCTAssertTrue(parseError.message.contains("initialize the SDK"))
        }
    }

    func testSetAccessGroupNoChangeInAccessGroup() async throws {
        await ParseKeychainAccessGroup.setCurrent(noKeychainAccessGroup)
        try await userLogin()
        try await ParseSwift.setAccessGroup(noKeychainAccessGroup.accessGroup,
                                            synchronizeAcrossDevices: noKeychainAccessGroup.isSyncingKeychainAcrossDevices)
        XCTAssertEqual(ParseSwift.configuration.keychainAccessGroup, noKeychainAccessGroup)
    }

    func testSetAccessGroupChangeInAccessGroup() async throws {
        try await userLogin()
        await ParseKeychainAccessGroup.setCurrent(keychainAccessGroup)
        try await ParseSwift.setAccessGroup(helloKeychainAccessGroup.accessGroup,
                                            synchronizeAcrossDevices: helloKeychainAccessGroup.isSyncingKeychainAcrossDevices)
        XCTAssertEqual(ParseSwift.configuration.keychainAccessGroup, helloKeychainAccessGroup)
    }
}
#endif
