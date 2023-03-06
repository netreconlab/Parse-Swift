//
//  ParseInstallationTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 9/7/20.
//  Copyright © 2020 Parse Community. All rights reserved.
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
        #if !os(Linux) && !os(Android) && !os(Windows)
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

                #if !os(Linux) && !os(Android) && !os(Windows)
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

                #if !os(Linux) && !os(Android) && !os(Windows)
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

        #if !os(Linux) && !os(Android) && !os(Windows)
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
        #if !os(Linux) && !os(Android) && !os(Windows)
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
}
