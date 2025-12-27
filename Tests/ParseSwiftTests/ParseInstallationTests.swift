//
//  ParseInstallationTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 9/7/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

// swiftlint:disable function_body_length

class ParseInstallationTests: XCTestCase { // swiftlint:disable:this type_body_length

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

    struct InstallationDefaultMerge: ParseInstallation {
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
    }

    struct InstallationDefault: ParseInstallation {
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
    }

    let testInstallationObjectId = "yarr"

    let loginUserName = "hello10"
    let loginPassword = "world"

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
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        try await KeychainStore.shared.deleteAll()
        #endif
        try await ParseStorage.shared.deleteAll()
    }

    @MainActor
    func login() async throws {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        do {
            _ = try await User.login(username: loginUserName, password: loginPassword)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    @MainActor
    func testSaveCommand() async throws {
        let installation = Installation()
        let command = try await installation.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/installations")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
    }

    @MainActor
    func testSaveUpdateCommand() async throws {
        var installation = Installation()
        let objectId = "yarr"
        installation.objectId = objectId

        let command = try await installation.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/installations/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
    }

    @MainActor
    func testCreateCommand() async throws {
        let installation = Installation()

        let command = try await installation.createCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/installations")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
    }

    @MainActor
    func testReplaceCommand() async throws {
        var installation = Installation()
        XCTAssertThrowsError(try installation.replaceCommand())
        let objectId = "yarr"
        installation.objectId = objectId

        let command = try installation.replaceCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/installations/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
    }

    @MainActor
    func testUpdateCommand() async throws {
        var installation = Installation()
        XCTAssertThrowsError(try installation.updateCommand())
        let objectId = "yarr"
        installation.objectId = objectId

        let command = try installation.updateCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/installations/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PATCH)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
    }

    @MainActor
    func testNewInstallationIdentifierIsLowercase() async throws {
        guard let installationIdFromContainer
            = await Installation.currentContainer().installationId else {
            XCTFail("Should have retreived installationId from container")
            return
        }

        XCTAssertEqual(installationIdFromContainer, installationIdFromContainer.lowercased())

        guard let installationIdFromCurrent = try? await Installation.current().installationId else {
            XCTFail("Should have retreived installationId from container")
            return
        }

        XCTAssertEqual(installationIdFromCurrent, installationIdFromCurrent.lowercased())
        XCTAssertEqual(installationIdFromContainer, installationIdFromCurrent)
    }

    func testDeviceTokenAsString() async throws {
        let data = Data([0, 1, 127, 128, 255])
        XCTAssertEqual(data.hexEncodedString(), "00017f80ff")
        XCTAssertEqual(data.hexEncodedString(options: .upperCase), "00017F80FF")
    }

    @MainActor
    func testInstallationMutableValuesCanBeChangedInMemory() async throws {
        let originalInstallation = try await Installation.current()
        var mutated = originalInstallation
        mutated.customKey = "Changed"
        mutated.setDeviceToken(Data([0, 1, 127, 128, 255]))
        await Installation.setCurrent(mutated)
        let current = try await Installation.current()
        XCTAssertNotEqual(originalInstallation.customKey, current.customKey)
        XCTAssertNotEqual(originalInstallation.deviceToken, current.customKey)
    }

    #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
    @MainActor
    func testInstallationImmutableFieldsCannotBeChangedInMemory() async throws {
        let originalInstallation = try await Installation.current()
        guard let originalDeviceType = originalInstallation.deviceType,
            let originalTimeZone = originalInstallation.timeZone,
            let originalAppName = originalInstallation.appName,
            let originalAppIdentifier = originalInstallation.appIdentifier,
            let originalAppVersion = originalInstallation.appVersion,
            let originalParseVersion = originalInstallation.parseVersion,
            let originalLocaleIdentifier = originalInstallation.localeIdentifier
            else {
                XCTFail("All of these Installation values should have unwraped")
            return
        }

        var mutated = originalInstallation
        mutated.installationId = "changed"
        mutated.deviceType = "changed"
        mutated.badge = 500
        mutated.timeZone = "changed"
        mutated.appName = "changed"
        mutated.appIdentifier = "changed"
        mutated.appVersion = "changed"
        mutated.parseVersion = "changed"
        mutated.localeIdentifier = "changed"
        await Installation.setCurrent(mutated)

        let current = try await Installation.current()
        XCTAssertEqual(mutated.installationId, current.installationId)
        XCTAssertEqual(originalDeviceType, current.deviceType)
        XCTAssertEqual(500, current.badge)
        XCTAssertEqual(originalTimeZone, current.timeZone)
        XCTAssertEqual(originalAppName, current.appName)
        XCTAssertEqual(originalAppIdentifier, current.appIdentifier)
        XCTAssertEqual(originalAppVersion, current.appVersion)
        XCTAssertEqual(originalParseVersion, current.parseVersion)
        XCTAssertEqual(originalLocaleIdentifier, current.localeIdentifier)
    }

    @MainActor
    func testInstallationCustomValuesSavedToKeychain() async throws {
        let customField = "Changed"
        var mutated = try await Installation.current()
        mutated.customKey = customField
        await Installation.setCurrent(mutated)
        guard let keychainInstallation: CurrentInstallationContainer<Installation>
            = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
            XCTFail("Should have pulled from Keychain")
            return
        }
        XCTAssertEqual(keychainInstallation.currentInstallation?.customKey, customField)
    }

    @MainActor
    func testInstallationImmutableFieldsCannotBeChangedInKeychain() async throws {
        let originalInstallation = try await Installation.current()
        guard let originalDeviceType = originalInstallation.deviceType,
            let originalTimeZone = originalInstallation.timeZone,
            let originalAppName = originalInstallation.appName,
            let originalAppIdentifier = originalInstallation.appIdentifier,
            let originalAppVersion = originalInstallation.appVersion,
            let originalParseVersion = originalInstallation.parseVersion,
            let originalLocaleIdentifier = originalInstallation.localeIdentifier
            else {
                XCTFail("All of these Installation values should have unwraped")
            return
        }

        var mutated = originalInstallation
        mutated.installationId = "changed"
        mutated.deviceType = "changed"
        mutated.badge = 500
        mutated.timeZone = "changed"
        mutated.appName = "changed"
        mutated.appIdentifier = "changed"
        mutated.appVersion = "changed"
        mutated.parseVersion = "changed"
        mutated.localeIdentifier = "changed"

        await Installation.setCurrent(mutated)

        guard let keychainInstallation: CurrentInstallationContainer<Installation>
            = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertEqual(mutated.installationId, keychainInstallation.currentInstallation?.installationId)
        XCTAssertEqual(originalDeviceType, keychainInstallation.currentInstallation?.deviceType)
        XCTAssertEqual(500, keychainInstallation.currentInstallation?.badge)
        XCTAssertEqual(originalTimeZone, keychainInstallation.currentInstallation?.timeZone)
        XCTAssertEqual(originalAppName, keychainInstallation.currentInstallation?.appName)
        XCTAssertEqual(originalAppIdentifier, keychainInstallation.currentInstallation?.appIdentifier)
        XCTAssertEqual(originalAppVersion, keychainInstallation.currentInstallation?.appVersion)
        XCTAssertEqual(originalParseVersion, keychainInstallation.currentInstallation?.parseVersion)
        XCTAssertEqual(originalLocaleIdentifier, keychainInstallation.currentInstallation?.localeIdentifier)
    }
    #endif

    @MainActor
    func testMerge() async throws {
        var original = try await Installation.current()
        original.objectId = "yolo"
        original.createdAt = Date()
        original.updatedAt = Date()
        original.badge = 10
        var acl = ParseACL()
        acl.publicRead = true
        original.ACL = acl

        var updated = original.mergeable
        updated.updatedAt = Calendar.current.date(byAdding: .init(day: 1), to: Date())
        updated.badge = 1
        updated.deviceToken = "12345"
        updated.customKey = "newKey"
        let merged = try updated.merge(with: original)
        XCTAssertEqual(merged.customKey, updated.customKey)
        XCTAssertEqual(merged.badge, updated.badge)
        XCTAssertEqual(merged.deviceType, original.deviceType)
        XCTAssertEqual(merged.deviceToken, updated.deviceToken)
        XCTAssertEqual(merged.channels, original.channels)
        XCTAssertEqual(merged.installationId, original.installationId)
        XCTAssertEqual(merged.timeZone, original.timeZone)
        XCTAssertEqual(merged.appName, original.appName)
        XCTAssertEqual(merged.appVersion, original.appVersion)
        XCTAssertEqual(merged.appIdentifier, original.appIdentifier)
        XCTAssertEqual(merged.parseVersion, original.parseVersion)
        XCTAssertEqual(merged.localeIdentifier, original.localeIdentifier)
        XCTAssertEqual(merged.ACL, original.ACL)
        XCTAssertEqual(merged.createdAt, original.createdAt)
        XCTAssertEqual(merged.updatedAt, updated.updatedAt)
    }

    @MainActor
    func testMerge2() async throws {
        var original = try await Installation.current()
        original.objectId = "yolo"
        original.createdAt = Date()
        original.updatedAt = Date()
        original.badge = 10
        original.deviceToken = "bruh"
        original.channels = ["halo"]
        var acl = ParseACL()
        acl.publicRead = true
        original.ACL = acl

        var updated = original.mergeable
        updated.updatedAt = Calendar.current.date(byAdding: .init(day: 1), to: Date())
        updated.customKey = "newKey"
        let merged = try updated.merge(with: original)
        XCTAssertEqual(merged.customKey, updated.customKey)
        XCTAssertEqual(merged.badge, original.badge)
        XCTAssertEqual(merged.deviceType, original.deviceType)
        XCTAssertEqual(merged.deviceToken, original.deviceToken)
        XCTAssertEqual(merged.channels, original.channels)
        XCTAssertEqual(merged.installationId, original.installationId)
        XCTAssertEqual(merged.timeZone, original.timeZone)
        XCTAssertEqual(merged.appName, original.appName)
        XCTAssertEqual(merged.appVersion, original.appVersion)
        XCTAssertEqual(merged.appIdentifier, original.appIdentifier)
        XCTAssertEqual(merged.parseVersion, original.parseVersion)
        XCTAssertEqual(merged.localeIdentifier, original.localeIdentifier)
        XCTAssertEqual(merged.ACL, original.ACL)
        XCTAssertEqual(merged.createdAt, original.createdAt)
        XCTAssertEqual(merged.updatedAt, updated.updatedAt)
    }

    @MainActor
    func testMergeDefaultImplementation() async throws {
        let currentInstallation = try await Installation.current()
        var original = InstallationDefaultMerge()
        original.installationId = currentInstallation.installationId
        original.objectId = "yolo"
        original.createdAt = Date()
        original.updatedAt = Date()
        original.badge = 10
        original.deviceToken = "bruh"
        original.channels = ["halo"]
        var acl = ParseACL()
        acl.publicRead = true
        original.ACL = acl

        var updated = original.set(\.customKey, to: "newKey")
        updated.updatedAt = Calendar.current.date(byAdding: .init(day: 1), to: Date())
        original.updatedAt = updated.updatedAt
        original.customKey = updated.customKey
        var merged = try updated.merge(with: original)
        merged.originalData = nil
        // Get dates in correct format from ParseDecoding strategy
        let encoded = try ParseCoding.jsonEncoder().encode(original)
        original = try ParseCoding.jsonDecoder().decode(InstallationDefaultMerge.self, from: encoded)
        XCTAssertEqual(merged, original)
    }

	@MainActor
	func testMergeableRetainsAutomaticallyComputedProperties() async throws {
		var original = try await Installation.current()
		original.objectId = "yolo"
		original.createdAt = Date()
		original.updatedAt = Date()
		original.badge = 10
		original.deviceToken = "12345"
		original.channels = ["halo"]
		original.customKey = "newKey"
		var acl = ParseACL()
		acl.publicRead = true
		original.ACL = acl

		// These properties should not be nil before merge
		XCTAssertNotNil(original.customKey)
		XCTAssertNotNil(original.deviceType)
		XCTAssertNotNil(original.deviceToken)
		XCTAssertNotNil(original.channels)
		XCTAssertNotNil(original.installationId)
		XCTAssertNotNil(original.ACL)
		XCTAssertNotNil(original.updatedAt)

		let mergeable = original.mergeable

		// These should always remain in the merge
		XCTAssertEqual(original.badge, mergeable.badge)
		XCTAssertEqual(original.timeZone, mergeable.timeZone)
		XCTAssertEqual(original.appName, mergeable.appName)
		XCTAssertEqual(original.appVersion, mergeable.appVersion)
		XCTAssertEqual(original.appIdentifier, mergeable.appIdentifier)
		XCTAssertEqual(original.parseVersion, mergeable.parseVersion)
		XCTAssertEqual(original.localeIdentifier, mergeable.localeIdentifier)
		XCTAssertEqual(original.createdAt, mergeable.createdAt)

		// All other properties should be nil
		XCTAssertNil(mergeable.customKey)
		XCTAssertNil(mergeable.deviceType)
		XCTAssertNil(mergeable.deviceToken)
		XCTAssertNil(mergeable.channels)
		XCTAssertNil(mergeable.installationId)
		XCTAssertNil(mergeable.ACL)
		XCTAssertNil(mergeable.updatedAt)
	}

	@MainActor
	func testMergeableRetainsAllPropertiesWhenNotSaved() async throws {
		var original = try await Installation.current()
		original.badge = 10
		original.deviceToken = "12345"
		original.channels = ["halo"]
		original.customKey = "newKey"
		var acl = ParseACL()
		acl.publicRead = true
		original.ACL = acl

		XCTAssertNil(original.objectId)
		XCTAssertNil(original.createdAt)
		XCTAssertNil(original.updatedAt)

		// These properties should not be nil before merge
		XCTAssertNotNil(original.customKey)
		XCTAssertNotNil(original.deviceType)
		XCTAssertNotNil(original.deviceToken)
		XCTAssertNotNil(original.channels)
		XCTAssertNotNil(original.installationId)
		XCTAssertNotNil(original.ACL)

		let mergeable = original.mergeable

		XCTAssertEqual(original.badge, mergeable.badge)
		XCTAssertEqual(original.timeZone, mergeable.timeZone)
		XCTAssertEqual(original.appName, mergeable.appName)
		XCTAssertEqual(original.appVersion, mergeable.appVersion)
		XCTAssertEqual(original.appIdentifier, mergeable.appIdentifier)
		XCTAssertEqual(original.parseVersion, mergeable.parseVersion)
		XCTAssertEqual(original.localeIdentifier, mergeable.localeIdentifier)
		XCTAssertEqual(original.customKey, mergeable.customKey)
		XCTAssertEqual(original.deviceType, mergeable.deviceType)
		XCTAssertEqual(original.deviceToken, mergeable.deviceToken)
		XCTAssertEqual(original.channels, mergeable.channels)
		XCTAssertEqual(original.installationId, mergeable.installationId)
		XCTAssertEqual(original.ACL, mergeable.ACL)
		XCTAssertEqual(original.createdAt, mergeable.createdAt)
		XCTAssertEqual(original.updatedAt, mergeable.updatedAt)
	}

    @MainActor
    func testMergeDifferentObjectId() async throws {
        var installation = Installation()
        installation.objectId = "yolo"
        var installation2 = installation
        installation2.objectId = "nolo"
        XCTAssertThrowsError(try installation2.merge(with: installation))
    }

    @MainActor
    func saveCurrentInstallation() async throws {
        let installation = try await Installation.current()

        var installationOnServer = installation
        installationOnServer.objectId = testInstallationObjectId
        installationOnServer.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

        let encoded: Data!
        do {
            encoded = try installationOnServer.getEncoder().encode(installationOnServer, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let saved = try await Installation.current().save()
        let newCurrentInstallation = try await Installation.current()
        XCTAssertTrue(saved.hasSameInstallationId(as: newCurrentInstallation))
        XCTAssertTrue(saved.hasSameObjectId(as: newCurrentInstallation))
        XCTAssertTrue(saved.hasSameObjectId(as: installationOnServer))
        XCTAssertTrue(saved.hasSameInstallationId(as: installationOnServer))
        XCTAssertNil(saved.ACL)
    }

    func testOriginalDataNeverSavesToKeychain() async throws {
        // Save current Installation
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        let original = try await Installation.current()
        var current = original
        current.originalData = Data()
        await Installation.setCurrent(current)

        let saved = try await Installation.current()
        XCTAssertTrue(saved.hasSameInstallationId(as: original))
        XCTAssertTrue(saved.hasSameObjectId(as: original))
        XCTAssertNotNil(current.originalData)
        XCTAssertNil(saved.originalData)
        XCTAssertEqual(saved.customKey, original.customKey)
        XCTAssertEqual(saved.badge, original.badge)
        XCTAssertEqual(saved.deviceType, original.deviceType)
        XCTAssertEqual(saved.deviceToken, original.deviceToken)
        XCTAssertEqual(saved.channels, original.channels)
        XCTAssertEqual(saved.installationId, original.installationId)
        XCTAssertEqual(saved.timeZone, original.timeZone)
        XCTAssertEqual(saved.appName, original.appName)
        XCTAssertEqual(saved.appVersion, original.appVersion)
        XCTAssertEqual(saved.appIdentifier, original.appIdentifier)
        XCTAssertEqual(saved.parseVersion, original.parseVersion)
        XCTAssertEqual(saved.localeIdentifier, original.localeIdentifier)
        XCTAssertEqual(saved.createdAt, original.createdAt)
        XCTAssertEqual(saved.updatedAt, original.updatedAt)
    }

    @MainActor
    func testFetch() async throws {
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        let installation = try await Installation.current()
        guard let savedObjectId = installation.objectId else {
            XCTFail("Should unwrap")
            return
        }
        XCTAssertEqual(savedObjectId, self.testInstallationObjectId)

        var serverResponse = installation
        serverResponse.updatedAt = installation.updatedAt?.addingTimeInterval(+300)
        serverResponse.customKey = "newValue"

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let fetched = try await installation.fetch()
        XCTAssert(fetched.hasSameObjectId(as: serverResponse))
        XCTAssert(fetched.hasSameInstallationId(as: serverResponse))
        let current = try await Installation.current()
        XCTAssertEqual(current, serverResponse)
        XCTAssertEqual(current.customKey, serverResponse.customKey)
    }

    @MainActor
    func testSaveCurrent() async throws {
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        var installation = try await Installation.current()
        guard let savedObjectId = installation.objectId else {
            XCTFail("Should unwrap")
            return
        }
        installation.customKey = "newValue"
        XCTAssertEqual(savedObjectId, self.testInstallationObjectId)

        var serverResponse = installation
        serverResponse.updatedAt = installation.updatedAt?.addingTimeInterval(+300)

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let fetched = try await installation.save()
        XCTAssert(fetched.hasSameObjectId(as: serverResponse))
        XCTAssert(fetched.hasSameInstallationId(as: serverResponse))
        let current = try await Installation.current()
        XCTAssertEqual(current, fetched)
        XCTAssertEqual(current.customKey, serverResponse.customKey)
    }

    @MainActor func testSaveMutableMergeCurrentInstallation() async throws {
        // Save current Installation
        try await testSave()
        MockURLProtocol.removeAll()

        let original = try await Installation.current()
        var response = original.mergeable
        response.createdAt = nil
        response.updatedAt = Calendar.current.date(byAdding: .init(day: 1), to: Date())

        let encoded: Data!
        do {
            encoded = try response.getEncoder().encode(response, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            response = try response.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        var updated = original.mergeable
        updated.customKey = "hello"
        updated.deviceToken = "1234"

        let saved = try await updated.save()
        let newCurrentInstallation = try await Installation.current()
        XCTAssertTrue(saved.hasSameInstallationId(as: newCurrentInstallation))
        XCTAssertTrue(saved.hasSameObjectId(as: newCurrentInstallation))
        XCTAssertTrue(saved.hasSameObjectId(as: response))
        XCTAssertEqual(saved.customKey, updated.customKey)
        XCTAssertEqual(saved.badge, original.badge)
        XCTAssertEqual(saved.deviceType, original.deviceType)
        XCTAssertEqual(saved.deviceToken, updated.deviceToken)
        XCTAssertEqual(saved.channels, original.channels)
        XCTAssertEqual(saved.installationId, original.installationId)
        XCTAssertEqual(saved.timeZone, original.timeZone)
        XCTAssertEqual(saved.appName, original.appName)
        XCTAssertEqual(saved.appVersion, original.appVersion)
        XCTAssertEqual(saved.appIdentifier, original.appIdentifier)
        XCTAssertEqual(saved.parseVersion, original.parseVersion)
        XCTAssertEqual(saved.localeIdentifier, original.localeIdentifier)
        XCTAssertEqual(saved.createdAt, original.createdAt)
        XCTAssertEqual(saved.updatedAt, response.updatedAt)
        XCTAssertNil(saved.originalData)
        XCTAssertEqual(saved.customKey, newCurrentInstallation.customKey)
        XCTAssertEqual(saved.badge, newCurrentInstallation.badge)
        XCTAssertEqual(saved.deviceType, newCurrentInstallation.deviceType)
        XCTAssertEqual(saved.deviceToken, newCurrentInstallation.deviceToken)
        XCTAssertEqual(saved.channels, newCurrentInstallation.channels)
        XCTAssertEqual(saved.installationId, newCurrentInstallation.installationId)
        XCTAssertEqual(saved.timeZone, newCurrentInstallation.timeZone)
        XCTAssertEqual(saved.appName, newCurrentInstallation.appName)
        XCTAssertEqual(saved.appVersion, newCurrentInstallation.appVersion)
        XCTAssertEqual(saved.appIdentifier, newCurrentInstallation.appIdentifier)
        XCTAssertEqual(saved.parseVersion, newCurrentInstallation.parseVersion)
        XCTAssertEqual(saved.localeIdentifier, newCurrentInstallation.localeIdentifier)
        XCTAssertEqual(saved.createdAt, newCurrentInstallation.createdAt)
        XCTAssertEqual(saved.updatedAt, newCurrentInstallation.updatedAt)
    }

    @MainActor
    func testSaveCurrentInstallationWithDefaultACL() async throws {
        try await login()
        guard let userObjectId = try await User.current().objectId else {
            XCTFail("Should have objectId")
            return
        }
        let defaultACL = try await ParseACL.setDefaultACL(ParseACL(),
                                                          withAccessForCurrentUser: true)

        let original = try await Installation.current()
        var installation = original
        installation.objectId = testInstallationObjectId
        installation.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.ACL = nil

        var installationOnServer = installation

        let encoded: Data!
        do {
            encoded = try installationOnServer.getEncoder().encode(installationOnServer, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let saved = try await original.save()
        let newCurrentInstallation = try await Installation.current()
        XCTAssertTrue(saved.hasSameInstallationId(as: newCurrentInstallation))
        XCTAssertTrue(saved.hasSameObjectId(as: newCurrentInstallation))
        XCTAssertTrue(saved.hasSameObjectId(as: installationOnServer))
        XCTAssertTrue(saved.hasSameInstallationId(as: installationOnServer))
        XCTAssertNotNil(saved.ACL)
        XCTAssertEqual(saved.ACL?.publicRead, defaultACL.publicRead)
        XCTAssertEqual(saved.ACL?.publicWrite, defaultACL.publicWrite)
        XCTAssertTrue(defaultACL.getReadAccess(objectId: userObjectId))
        XCTAssertTrue(defaultACL.getWriteAccess(objectId: userObjectId))
    }

    @MainActor
    func testUpdateWithDefaultACL() async throws {
        try await login()
        _ = try await ParseACL.setDefaultACL(ParseACL(),
                                             withAccessForCurrentUser: true)

        var installation = Installation()
        installation.objectId = testInstallationObjectId
        installation.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.ACL = nil
        installation.installationId = "hello"

        var installationOnServer = installation
        installationOnServer.createdAt = nil
        installationOnServer.updatedAt = Date()

        let encoded: Data!
        do {
            encoded = try installationOnServer.getEncoder().encode(installationOnServer, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let saved = try await installation.save()
        XCTAssertTrue(saved.hasSameObjectId(as: installationOnServer))
        XCTAssertTrue(saved.hasSameInstallationId(as: installationOnServer))
        XCTAssertNil(saved.ACL)
    }

    @MainActor
    func testSave() async throws {
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        var installation = Installation()
        installation.customKey = "newValue"
        installation.installationId = "123"

        var serverResponse = installation
        serverResponse.objectId = "yolo"
        serverResponse.createdAt = Date()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                // Get dates in correct format from ParseDecoding strategy
                serverResponse = try serverResponse.getDecoder().decode(Installation.self, from: encoded)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let saved = try await installation.save()
        XCTAssert(saved.hasSameObjectId(as: serverResponse))
        XCTAssert(saved.hasSameInstallationId(as: serverResponse))
        XCTAssertEqual(saved.createdAt, serverResponse.createdAt)
        XCTAssertEqual(saved.updatedAt, serverResponse.createdAt)
    }

    @MainActor
    func testCreate() async throws {
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        var installation = Installation()
        installation.customKey = "newValue"
        installation.installationId = "123"

        var serverResponse = installation
        serverResponse.objectId = "yolo"
        serverResponse.createdAt = Date()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                // Get dates in correct format from ParseDecoding strategy
                serverResponse = try serverResponse.getDecoder().decode(Installation.self, from: encoded)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let saved = try await installation.create()
        XCTAssert(saved.hasSameObjectId(as: serverResponse))
        XCTAssert(saved.hasSameInstallationId(as: serverResponse))
        XCTAssertEqual(saved.createdAt, serverResponse.createdAt)
        XCTAssertEqual(saved.updatedAt, serverResponse.createdAt)
    }

    @MainActor
    func testReplaceCreate() async throws {
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        var installation = Installation()
        installation.objectId = "yolo"
        installation.customKey = "newValue"
        installation.installationId = "123"

        var serverResponse = installation
        serverResponse.createdAt = Date()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                // Get dates in correct format from ParseDecoding strategy
                serverResponse = try serverResponse.getDecoder().decode(Installation.self, from: encoded)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let saved = try await installation.replace()
        XCTAssert(saved.hasSameObjectId(as: serverResponse))
        XCTAssert(saved.hasSameInstallationId(as: serverResponse))
        XCTAssertEqual(saved.createdAt, serverResponse.createdAt)
        XCTAssertEqual(saved.updatedAt, serverResponse.createdAt)
    }

    @MainActor
    func testReplaceUpdate() async throws {
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        var installation = Installation()
        installation.objectId = "yolo"
        installation.customKey = "newValue"
        installation.installationId = "123"

        var serverResponse = installation
        serverResponse.updatedAt = Date()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                // Get dates in correct format from ParseDecoding strategy
                serverResponse = try serverResponse.getDecoder().decode(Installation.self, from: encoded)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let saved = try await installation.replace()
        XCTAssert(saved.hasSameObjectId(as: serverResponse))
        XCTAssert(saved.hasSameInstallationId(as: serverResponse))
        XCTAssertEqual(saved.updatedAt, serverResponse.updatedAt)
    }

    @MainActor
    func testUpdate() async throws {
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        var installation = Installation()
        installation.objectId = "yolo"
        installation.customKey = "newValue"
        installation.installationId = "123"

        var serverResponse = installation
        serverResponse.updatedAt = Date()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                // Get dates in correct format from ParseDecoding strategy
                serverResponse = try serverResponse.getDecoder().decode(Installation.self, from: encoded)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let saved = try await installation.update()
        XCTAssert(saved.hasSameObjectId(as: serverResponse))
        XCTAssert(saved.hasSameInstallationId(as: serverResponse))
        XCTAssertEqual(saved.updatedAt, serverResponse.updatedAt)
    }

    @MainActor
    func testUpdateDefaultMerge() async throws {
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        var installation = InstallationDefaultMerge()
        installation.objectId = "yolo"
        installation.installationId = "123"

        var serverResponse = installation
        serverResponse.updatedAt = Date()
        serverResponse.customKey = "newValue"

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                // Get dates in correct format from ParseDecoding strategy
                serverResponse = try serverResponse.getDecoder().decode(InstallationDefaultMerge.self, from: encoded)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        installation = installation.set(\.customKey, to: "newValue")
        let saved = try await installation.update()
        XCTAssertEqual(saved, serverResponse)
    }

    func testUpdateMutableMergeCurrentInstallation() async throws {
        // Save current Installation
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        let original = try await Installation.current()
        var originalResponse = original.mergeable
        originalResponse.createdAt = nil
        originalResponse.updatedAt = Calendar.current.date(byAdding: .init(day: 1), to: Date())

        let encoded: Data!
        do {
            encoded = try originalResponse.getEncoder().encode(originalResponse, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            originalResponse = try originalResponse.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        let response = originalResponse
        var originalUpdate = original.mergeable
        originalUpdate.customKey = "hello"
        originalUpdate.deviceToken = "1234"
        let updated = originalUpdate

        let saved = try await updated.update()
        let newCurrentInstallation = try await Installation.current()
        XCTAssertTrue(saved.hasSameInstallationId(as: newCurrentInstallation))
        XCTAssertTrue(saved.hasSameObjectId(as: newCurrentInstallation))
        XCTAssertTrue(saved.hasSameObjectId(as: response))
        XCTAssertEqual(saved.customKey, updated.customKey)
        XCTAssertEqual(saved.badge, original.badge)
        XCTAssertEqual(saved.deviceType, original.deviceType)
        XCTAssertEqual(saved.deviceToken, updated.deviceToken)
        XCTAssertEqual(saved.channels, original.channels)
        XCTAssertEqual(saved.installationId, original.installationId)
        XCTAssertEqual(saved.timeZone, original.timeZone)
        XCTAssertEqual(saved.appName, original.appName)
        XCTAssertEqual(saved.appVersion, original.appVersion)
        XCTAssertEqual(saved.appIdentifier, original.appIdentifier)
        XCTAssertEqual(saved.parseVersion, original.parseVersion)
        XCTAssertEqual(saved.localeIdentifier, original.localeIdentifier)
        XCTAssertEqual(saved.createdAt, original.createdAt)
        XCTAssertEqual(saved.updatedAt, response.updatedAt)
        XCTAssertNil(saved.originalData)
        XCTAssertEqual(saved.customKey, newCurrentInstallation.customKey)
        XCTAssertEqual(saved.badge, newCurrentInstallation.badge)
        XCTAssertEqual(saved.deviceType, newCurrentInstallation.deviceType)
        XCTAssertEqual(saved.deviceToken, newCurrentInstallation.deviceToken)
        XCTAssertEqual(saved.channels, newCurrentInstallation.channels)
        XCTAssertEqual(saved.installationId, newCurrentInstallation.installationId)
        XCTAssertEqual(saved.timeZone, newCurrentInstallation.timeZone)
        XCTAssertEqual(saved.appName, newCurrentInstallation.appName)
        XCTAssertEqual(saved.appVersion, newCurrentInstallation.appVersion)
        XCTAssertEqual(saved.appIdentifier, newCurrentInstallation.appIdentifier)
        XCTAssertEqual(saved.parseVersion, newCurrentInstallation.parseVersion)
        XCTAssertEqual(saved.localeIdentifier, newCurrentInstallation.localeIdentifier)
        XCTAssertEqual(saved.createdAt, newCurrentInstallation.createdAt)
        XCTAssertEqual(saved.updatedAt, newCurrentInstallation.updatedAt)
    }

    func testUpdateMutableMergeCurrentInstallationDefault() async throws {
        // Save current Installation
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        let original = try await InstallationDefault.current()
        var originalResponse = original.mergeable
        originalResponse.createdAt = nil
        originalResponse.updatedAt = Calendar.current.date(byAdding: .init(day: 1), to: Date())

        let encoded: Data!
        do {
            encoded = try originalResponse.getEncoder().encode(originalResponse, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            originalResponse = try originalResponse.getDecoder().decode(InstallationDefault.self,
                                                                        from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        let response = originalResponse
        var originalUpdate = original.mergeable
        originalUpdate.deviceToken = "1234"
        let updated = originalUpdate

        let saved = try await updated.update()
        let newCurrentInstallation = try await Installation.current()
        XCTAssertTrue(saved.hasSameInstallationId(as: newCurrentInstallation))
        XCTAssertTrue(saved.hasSameObjectId(as: newCurrentInstallation))
        XCTAssertTrue(saved.hasSameObjectId(as: response))
        XCTAssertEqual(saved.badge, original.badge)
        XCTAssertEqual(saved.deviceType, original.deviceType)
        XCTAssertEqual(saved.deviceToken, updated.deviceToken)
        XCTAssertEqual(saved.channels, original.channels)
        XCTAssertEqual(saved.installationId, original.installationId)
        XCTAssertEqual(saved.timeZone, original.timeZone)
        XCTAssertEqual(saved.appName, original.appName)
        XCTAssertEqual(saved.appVersion, original.appVersion)
        XCTAssertEqual(saved.appIdentifier, original.appIdentifier)
        XCTAssertEqual(saved.parseVersion, original.parseVersion)
        XCTAssertEqual(saved.localeIdentifier, original.localeIdentifier)
        XCTAssertEqual(saved.createdAt, original.createdAt)
        XCTAssertEqual(saved.updatedAt, response.updatedAt)
        XCTAssertNil(saved.originalData)
        XCTAssertEqual(saved.badge, newCurrentInstallation.badge)
        XCTAssertEqual(saved.deviceType, newCurrentInstallation.deviceType)
        XCTAssertEqual(saved.deviceToken, newCurrentInstallation.deviceToken)
        XCTAssertEqual(saved.channels, newCurrentInstallation.channels)
        XCTAssertEqual(saved.installationId, newCurrentInstallation.installationId)
        XCTAssertEqual(saved.timeZone, newCurrentInstallation.timeZone)
        XCTAssertEqual(saved.appName, newCurrentInstallation.appName)
        XCTAssertEqual(saved.appVersion, newCurrentInstallation.appVersion)
        XCTAssertEqual(saved.appIdentifier, newCurrentInstallation.appIdentifier)
        XCTAssertEqual(saved.parseVersion, newCurrentInstallation.parseVersion)
        XCTAssertEqual(saved.localeIdentifier, newCurrentInstallation.localeIdentifier)
        XCTAssertEqual(saved.createdAt, newCurrentInstallation.createdAt)
        XCTAssertEqual(saved.updatedAt, newCurrentInstallation.updatedAt)
    }

    @MainActor
    func testUpdateClientMissingObjectId() async throws {
        var installation = Installation()
        installation.installationId = "123"
        do {
            _ = try await installation.update()
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted to ParseError")
                return
            }
            XCTAssertEqual(parseError.code, .missingObjectId)
        }
    }

    @MainActor
    func testDelete() async throws {
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        let installation = try await Installation.current()
        guard let savedObjectId = installation.objectId else {
            XCTFail("Should unwrap")
            return
        }
        XCTAssertEqual(savedObjectId, self.testInstallationObjectId)

        var serverResponse = installation
        serverResponse.updatedAt = installation.updatedAt?.addingTimeInterval(+300)
        serverResponse.customKey = "newValue"

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        _ = try await installation.delete()
        if let newInstallation = try? await Installation.current() {
            XCTAssertFalse(installation.hasSameInstallationId(as: newInstallation))
        }
    }

    @MainActor
    func testDeleteError() async throws {
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        let installation = try await Installation.current()
        guard let savedObjectId = installation.objectId else {
            XCTFail("Should unwrap")
            return
        }
        XCTAssertEqual(savedObjectId, self.testInstallationObjectId)

        let serverResponse = ParseError(code: .objectNotFound, message: "not found")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        do {
            _ = try await installation.delete()
            XCTFail("Should have thrown error")
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("Should be ParseError")
                return
            }
            XCTAssertEqual(error.message, serverResponse.message)
        }

        if let newInstallation = try? await Installation.current() {
            XCTAssertTrue(installation.hasSameInstallationId(as: newInstallation))
        }
    }

    @MainActor
    func testFetchAll() async throws {
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        var installation = try await Installation.current()
        installation.updatedAt = installation.updatedAt?.addingTimeInterval(+300)
        installation.customKey = "newValue"
        let installationOnServer = QueryResponse<Installation>(results: [installation], count: 1)

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
            // Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(installation)
            installation = try installation.getDecoder().decode(Installation.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let fetchedObjects = try await [installation].fetchAll()
        let current = try await Installation.current()
        guard let updatedCurrentDate = current.updatedAt else {
            XCTFail("Should unwrap current date")
            return
        }
        for object in fetchedObjects {
            switch object {
            case .success(let fetched):
                XCTAssert(fetched.hasSameObjectId(as: installation))
                guard let fetchedCreatedAt = fetched.createdAt,
                    let fetchedUpdatedAt = fetched.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt = installation.createdAt,
                    let originalUpdatedAt = installation.updatedAt,
                    let serverUpdatedAt = installation.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
                XCTAssertEqual(fetchedUpdatedAt, serverUpdatedAt)
                XCTAssertEqual(current.customKey, installation.customKey)

                // Should be updated in memory
                XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)

                #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
                // Should be updated in Keychain
                let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>?
                    = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation)
                guard let keychainUpdatedCurrentDate = keychainInstallation?.currentInstallation?.updatedAt else {
                    XCTFail("Should get object from Keychain")
                    return
                }
                XCTAssertEqual(keychainUpdatedCurrentDate, serverUpdatedAt)
                #endif
            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func testSaveAll() async throws {
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        var installation = try await Installation.current()
        installation.createdAt = nil
        installation.updatedAt = installation.updatedAt?.addingTimeInterval(+300)
        installation.customKey = "newValue"
        let installationOnServer = [BatchResponseItem<Installation>(success: installation, error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
            // Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(installation)
            installation = try installation.getDecoder().decode(Installation.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let savedObjects = try await [installation].saveAll()
        let current = try await Installation.current()
        guard let updatedCurrentDate = current.updatedAt else {
            XCTFail("Should unwrap current date")
            return
        }
        for object in savedObjects {
            switch object {
            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: installation))
                XCTAssert(saved.hasSameInstallationId(as: installation))
                guard let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalUpdatedAt = installation.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                XCTAssertEqual(current.customKey, installation.customKey)

                // Should be updated in memory
                XCTAssertEqual(updatedCurrentDate, originalUpdatedAt)

                #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
                // Should be updated in Keychain
                let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>?
                    = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation)
                guard let keychainUpdatedCurrentDate = keychainInstallation?.currentInstallation?.updatedAt else {
                    XCTFail("Should get object from Keychain")
                    return
                }
                XCTAssertEqual(keychainUpdatedCurrentDate, originalUpdatedAt)
                #endif
            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func testCreateAll() async throws {
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        var installation = Installation()
        installation.customKey = "newValue"
        installation.installationId = "123"

        var serverResponse = installation
        serverResponse.objectId = "yolo"
        serverResponse.createdAt = Date()
        let installationOnServer = [BatchResponseItem<Installation>(success: serverResponse, error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
            // Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(serverResponse)
            serverResponse = try installation.getDecoder().decode(Installation.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let saved = try await [installation].createAll()
        saved.forEach {
            switch $0 {
            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: serverResponse))
                XCTAssert(saved.hasSameInstallationId(as: serverResponse))
                guard let savedCreatedAt = saved.createdAt,
                    let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt = serverResponse.createdAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                XCTAssertEqual(savedUpdatedAt, originalCreatedAt)

            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func testReplaceAllCreate() async throws {
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        var installation = Installation()
        installation.customKey = "newValue"
        installation.installationId = "123"
        installation.objectId = "yolo"

        var serverResponse = installation
        serverResponse.createdAt = Date()
        let installationOnServer = [BatchResponseItem<Installation>(success: serverResponse, error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
            // Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(serverResponse)
            serverResponse = try installation.getDecoder().decode(Installation.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let saved = try await [installation].replaceAll()
        saved.forEach {
            switch $0 {
            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: serverResponse))
                XCTAssert(saved.hasSameInstallationId(as: serverResponse))
                XCTAssertEqual(saved.createdAt, serverResponse.createdAt)
                XCTAssertEqual(saved.updatedAt, serverResponse.createdAt)

            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func testReplaceAllUpdate() async throws {
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        var installation = Installation()
        installation.customKey = "newValue"
        installation.installationId = "123"
        installation.objectId = "yolo"

        var serverResponse = installation
        serverResponse.updatedAt = Date()
        let installationOnServer = [BatchResponseItem<Installation>(success: serverResponse, error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
            // Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(serverResponse)
            serverResponse = try installation.getDecoder().decode(Installation.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let saved = try await [installation].replaceAll()
        saved.forEach {
            switch $0 {
            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: serverResponse))
                XCTAssert(saved.hasSameInstallationId(as: serverResponse))
                guard let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalUpdatedAt = serverResponse.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)

            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func testUpdateAll() async throws {
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        var installation = Installation()
        installation.customKey = "newValue"
        installation.installationId = "123"
        installation.objectId = "yolo"

        var serverResponse = installation
        serverResponse.updatedAt = Date()
        let installationOnServer = [BatchResponseItem<Installation>(success: serverResponse, error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
            // Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(serverResponse)
            serverResponse = try installation.getDecoder().decode(Installation.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let saved = try await [installation].updateAll()
        saved.forEach {
            switch $0 {
            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: serverResponse))
                XCTAssert(saved.hasSameInstallationId(as: serverResponse))
                guard let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalUpdatedAt = serverResponse.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)

            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func testDeleteAll() async throws {
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        let installation = try await Installation.current()
        let installationOnServer = [BatchResponseItem<NoBody>(success: NoBody(), error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let deleted = try await [installation].deleteAll()
        for object in deleted {
            if case let .failure(error) = object {
                XCTFail("Should have deleted: \(error.localizedDescription)")
            }
            if let newInstallation = try? await Installation.current() {
                XCTAssertFalse(installation.hasSameInstallationId(as: newInstallation))
            }
        }
    }

    @MainActor
    func testBecome() async throws {
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        let installation = try await Installation.current()
        guard let savedObjectId = installation.objectId else {
            XCTFail("Should unwrap")
            return
        }
        XCTAssertEqual(savedObjectId, self.testInstallationObjectId)

        var installationOnServer = installation
        installationOnServer.createdAt = installation.updatedAt
        installationOnServer.updatedAt = installation.updatedAt?.addingTimeInterval(+300)
        installationOnServer.customKey = "newValue"
        installationOnServer.installationId = "wowsers"
        installationOnServer.channels = ["yo"]
        installationOnServer.deviceToken = "no"

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
            // Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self,
                                                                                from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let saved = try await Installation.become("wowsers")
        let currentInstallation = try await Installation.current()
        XCTAssertTrue(installationOnServer.hasSameObjectId(as: saved))
        XCTAssertTrue(installationOnServer.hasSameInstallationId(as: saved))
        XCTAssertTrue(installationOnServer.hasSameObjectId(as: currentInstallation))
        XCTAssertTrue(installationOnServer.hasSameInstallationId(as: currentInstallation))
        guard let savedCreatedAt = saved.createdAt else {
            XCTFail("Should unwrap dates")
            return
        }
        guard let originalCreatedAt = installationOnServer.createdAt else {
            XCTFail("Should unwrap dates")
            return
        }
        XCTAssertEqual(savedCreatedAt, originalCreatedAt)
        XCTAssertEqual(saved.channels, installationOnServer.channels)
        XCTAssertEqual(saved.deviceToken, installationOnServer.deviceToken)

        // Should be updated in memory
        let current = try await Installation.current()
        XCTAssertEqual(current.installationId, "wowsers")
        XCTAssertEqual(current.customKey, installationOnServer.customKey)
        XCTAssertEqual(current.channels, installationOnServer.channels)
        XCTAssertEqual(current.deviceToken, installationOnServer.deviceToken)

        #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        // Should be updated in Keychain
        let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>?
            = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation)
        XCTAssertEqual(keychainInstallation?.currentInstallation?.installationId, "wowsers")
        XCTAssertEqual(keychainInstallation?.currentInstallation?.channels, installationOnServer.channels)
        XCTAssertEqual(keychainInstallation?.currentInstallation?.deviceToken, installationOnServer.deviceToken)
        #endif
    }

    @MainActor
    func testBecomeSameObjectId() async throws {
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        let installation = try await Installation.current()
        guard let savedObjectId = installation.objectId else {
            XCTFail("Should unwrap")
            return
        }
        XCTAssertEqual(savedObjectId, self.testInstallationObjectId)

        let saved = try await Installation.become(testInstallationObjectId)
        let currentInstallation = try await Installation.current()
        XCTAssertEqual(saved, currentInstallation)
    }

    @MainActor
    func testBecomeMissingObjectId() async throws {
        try await ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentInstallation)
        #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        try await KeychainStore.shared.delete(valueFor: ParseStorage.Keys.currentInstallation)
        #endif
        await Installation.setCurrent(nil)

        do {
            _ = try await Installation.become(testInstallationObjectId)
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("does not exist"))
        }
    }

    func saveCurrentAsync(installation: Installation,
                          installationOnServer: Installation,
                          callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Update installation1")
        installation.save(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                Task {
                    do {
                        let currentInstallation = try await Installation.current()
                        XCTAssertTrue(saved.hasSameObjectId(as: currentInstallation))
                        XCTAssertTrue(saved.hasSameInstallationId(as: currentInstallation))
                        XCTAssertTrue(saved.hasSameObjectId(as: installationOnServer))
                        XCTAssertTrue(saved.hasSameInstallationId(as: installationOnServer))
                        guard let savedUpdatedAt = saved.updatedAt else {
                            XCTFail("Should unwrap dates")
                            expectation1.fulfill()
                            return
                        }
                        guard let serverUpdatedAt = installationOnServer.updatedAt else {
                            XCTFail("Should unwrap dates")
                            expectation1.fulfill()
                            return
                        }
                        XCTAssertEqual(savedUpdatedAt, serverUpdatedAt)
                        XCTAssertNil(saved.ACL)
                        XCTAssertNil(currentInstallation.ACL)
                        expectation1.fulfill()
                    } catch {
                        XCTFail(error.localizedDescription)
                        expectation1.fulfill()
                    }
                }

            case .failure(let error):
                XCTFail(error.localizedDescription)
                expectation1.fulfill()
            }
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testFetchCommand() {
        var installation = Installation()
        XCTAssertThrowsError(try installation.fetchCommand(include: nil))
        let objectId = "yarr"
        installation.objectId = objectId
        do {
            let command = try installation.fetchCommand(include: nil)
            XCTAssertNotNil(command)
            XCTAssertEqual(command.path.urlComponent, "/installations/\(objectId)")
            XCTAssertEqual(command.method, API.Method.GET)
            XCTAssertNil(command.params)
            XCTAssertNil(command.body)
        } catch {
            XCTFail(error.localizedDescription)
        }

        let installation2 = Installation()
        XCTAssertThrowsError(try installation2.fetchCommand(include: nil))
    }

    func testFetchIncludeCommand() {
        var installation = Installation()
        let objectId = "yarr"
        installation.objectId = objectId
        let includeExpected = ["include": "[\"yolo\", \"test\"]"]
        do {
            let command = try installation.fetchCommand(include: ["yolo", "test"])
            XCTAssertNotNil(command)
            XCTAssertEqual(command.path.urlComponent, "/installations/\(objectId)")
            XCTAssertEqual(command.method, API.Method.GET)
            XCTAssertEqual(command.params?.keys.first, includeExpected.keys.first)
            if let value = command.params?.values.first,
                let includeValue = value {
                XCTAssertTrue(includeValue.contains("\"yolo\""))
            } else {
                XCTFail("Should have unwrapped value")
            }
            XCTAssertNil(command.body)
        } catch {
            XCTFail(error.localizedDescription)
        }

        let installation2 = Installation()
        XCTAssertThrowsError(try installation2.fetchCommand(include: nil))
    }

#if compiler(>=5.8.0) || (compiler(<5.8.0) && !os(iOS) && !os(tvOS))
    func testSaveCurrentAsyncMainQueue() async throws {
        var installation = try await Installation.current()
        installation.objectId = testInstallationObjectId
        installation.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.ACL = nil

        var installationOnServer = installation

        let encoded: Data!
        do {
            let encodedOriginal = try ParseCoding.jsonEncoder().encode(installation)
            // Get dates in correct format from ParseDecoding strategy
            installation = try installation.getDecoder().decode(Installation.self, from: encodedOriginal)

            encoded = try installationOnServer.getEncoder().encode(installationOnServer, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        self.saveCurrentAsync(installation: installation,
                              installationOnServer: installationOnServer,
                              callbackQueue: .main)
    }

    @MainActor
    func testFetchUpdatedCurrentInstallation() async throws { // swiftlint:disable:this function_body_length
        try await testSave()
        MockURLProtocol.removeAll()

        let installation = try await Installation.current()

        guard let savedObjectId = installation.objectId else {
            XCTFail("Should unwrap")
            return
        }
        XCTAssertEqual(savedObjectId, self.testInstallationObjectId)

        var installationOnServer = installation
        installationOnServer.updatedAt = installation.updatedAt?.addingTimeInterval(+300)
        installationOnServer.customKey = "newValue"

        let encoded: Data!
        do {
            encoded = try installationOnServer.getEncoder().encode(installationOnServer, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let fetched = try await installation.fetch()
        let currentInstallation = try await Installation.current()
        XCTAssertTrue(fetched.hasSameObjectId(as: currentInstallation))
        XCTAssertTrue(fetched.hasSameInstallationId(as: currentInstallation))
        XCTAssertTrue(fetched.hasSameObjectId(as: installationOnServer))
        XCTAssertTrue(fetched.hasSameInstallationId(as: installationOnServer))
        guard let fetchedCreatedAt = fetched.createdAt,
            let fetchedUpdatedAt = fetched.updatedAt else {
                XCTFail("Should unwrap dates")
                return
        }
        guard let originalCreatedAt = installationOnServer.createdAt,
            let originalUpdatedAt = installation.updatedAt,
            let serverUpdatedAt = installationOnServer.updatedAt else {
                XCTFail("Should unwrap dates")
                return
        }
        XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
        XCTAssertGreaterThan(fetchedUpdatedAt, originalUpdatedAt)
        XCTAssertEqual(fetchedUpdatedAt, serverUpdatedAt)
        XCTAssertEqual(currentInstallation.customKey, installationOnServer.customKey)

        // Should be updated in memory
        guard let updatedCurrentDate = currentInstallation.updatedAt else {
            XCTFail("Should unwrap current date")
            return
        }
        XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)

        // Should be updated in Keychain
        #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        guard let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>
            = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation),
            let keychainUpdatedCurrentDate = keychainInstallation.currentInstallation?.updatedAt else {
                XCTFail("Should get object from Keychain")
            return
        }
        XCTAssertEqual(keychainUpdatedCurrentDate, serverUpdatedAt)
        #endif
    }
#endif

    @MainActor
    func testDeleteCommand() async throws {
        var installation = Installation()
        let objectId = "yarr"
        installation.objectId = objectId
        let command = try await installation.deleteCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/installations/\(objectId)")
        XCTAssertEqual(command.method, API.Method.DELETE)
        XCTAssertNil(command.body)

        let installation2 = Installation()
        do {
            _ = try await installation2.deleteCommand()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertNotNil(error as? ParseError)
        }
    }

    func testDeleteCurrent() async throws {
        try await testSave()

        let installation = try await Installation.current()

        try await installation.delete(options: [])
        if let newInstallation = try? await Installation.current() {
            XCTAssertFalse(installation.hasSameInstallationId(as: newInstallation))
        }

        try await installation.delete(options: [.usePrimaryKey])
    }
}
