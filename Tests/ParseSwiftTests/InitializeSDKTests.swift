//
//  InitializeSDKTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 4/3/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import XCTest
@testable import ParseSwift

// swiftlint:disable function_body_length type_body_length

class InitializeSDKTests: XCTestCase {

    struct User: ParseUser {
        var username: String?
        var email: String?
        var emailVerified: Bool?
        var password: String?
        var authData: [String: [String: String]?]?
        var originalData: Data?
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseSwift.ParseACL?
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
    }

    struct Config: ParseConfig {
        var welcomeMessage: String?
        var winningNumber: Int?
    }

    override func setUp() async throws {
        try await super.setUp()
        guard let url = URL(string: "http://localhost:1337/parse") else {
            XCTFail("Should create valid URL")
            return
        }
        Parse.configuration = .init(applicationId: "applicationId",
                                    primaryKey: "primaryKey",
                                    serverURL: url)
        Parse.configuration.isTestingSDK = true
    }

    override func tearDown() async throws {
        try await super.tearDown()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try await KeychainStore.shared?.deleteAll()
        try await KeychainStore.objectiveC?.deleteAllObjectiveC()
        try await KeychainStore.old?.deleteAll()
        URLSession.shared.configuration.urlCache?.removeAllCachedResponses()
        #endif
        try await ParseStorage.shared.deleteAll()
        await ParseStorage.shared.setBackingStoreToNil()
    }

    func pretendToBeInitialized() async {
        Parse.configuration.isInitialized = true
        #if !os(Linux) && !os(Android) && !os(Windows)
        await KeychainStore.createShared()
        #endif
    }

    func setupInitialStorage() async throws {
        let memory = InMemoryPrimitiveStore()
        await ParseStorage.shared.use(memory)
        #if !os(Linux) && !os(Android) && !os(Windows)
        await KeychainStore.createShared()
        #endif
        try await BaseParseInstallation.create()
    }

    func initializeAfter() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            Task {
                guard let url = URL(string: "http://localhost:1337/parse") else {
                    XCTFail("Should create valid URL")
                    return
                }

                try await ParseSwift.initialize(applicationId: "applicationId",
                                                clientKey: "clientKey",
                                                primaryKey: "primaryKey",
                                                serverURL: url,
                                                testing: true) { (_, credential) in
                    credential(.performDefaultHandling, nil)
                }
            }
        }
    }

    func testUserWaitsForSDKInitialization() async throws {
        try await setupInitialStorage()
        initializeAfter()
        do {
            _ = try await User.current()
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("current user"))
        }
    }

    func testInstallationWaitsForSDKInitialization() async throws {
        try await setupInitialStorage()
        XCTAssertFalse(ParseConfiguration.checkIfConfigured())
        initializeAfter()
        _ = try await Installation.current()
        XCTAssertTrue(ParseConfiguration.checkIfConfigured())
    }

    func testConfigWaitsForSDKInitialization() async throws {
        try await setupInitialStorage()
        initializeAfter()
        do {
            _ = try await Config.current()
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("no current"))
        }
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func addCachedResponse() {
        if URLSession.parse.configuration.urlCache == nil {
            URLSession.parse.configuration.urlCache = .init()
        }
        guard let server = URL(string: "http://parse.com"),
              let data = "Test".data(using: .utf8) else {
            XCTFail("Should have unwrapped")
            return
        }

        let response = URLResponse(url: server, mimeType: nil,
                                   expectedContentLength: data.count,
                                   textEncodingName: nil)
        URLSession.parse.configuration.urlCache?
            .storeCachedResponse(.init(response: response,
                                       data: data),
                                 for: .init(url: server))
        guard let currentCache = URLSession.parse.configuration.urlCache else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertTrue(currentCache.currentMemoryUsage > 0)
    }
/*
    func testDeleteKeychainOnFirstRun() async throws {
        let memory = InMemoryKeyValueStore()
        await ParseStorage.shared.use(memory)
        guard let server = URL(string: "http://parse.com") else {
            XCTFail("Should have unwrapped")
            return
        }
        Parse.configuration = ParseConfiguration(applicationId: "yo",
                                                      serverURL: server,
                                                      isDeletingKeychainIfNeeded: false)
        let key = "Hello"
        let value = "World"
        try KeychainStore.shared.set(value, for: key)
        addCachedResponse()

        // Keychain should contain value on first run
        ParseSwift.deleteKeychainIfNeeded()

        do {
            let storedValue: String? = try KeychainStore.shared.get(valueFor: key)
            XCTAssertEqual(storedValue, value)
            guard let firstRun = UserDefaults.standard.object(forKey: ParseConstants.bundlePrefix) as? String else {
                XCTFail("Should have unwrapped")
                return
            }
            XCTAssertEqual(firstRun, ParseConstants.bundlePrefix)

            // Keychain should remain unchanged on 2+ runs
            ParseSwift.configuration.isDeletingKeychainIfNeeded = true
            ParseSwift.deleteKeychainIfNeeded()
            let storedValue2: String? = try KeychainStore.shared.get(valueFor: key)
            XCTAssertEqual(storedValue2, value)
            guard let firstRun2 = UserDefaults.standard
                    .object(forKey: ParseConstants.bundlePrefix) as? String else {
                        XCTFail("Should have unwrapped")
                        return
                    }
            XCTAssertEqual(firstRun2, ParseConstants.bundlePrefix)

            // Keychain should delete on first run
            UserDefaults.standard.removeObject(forKey: ParseConstants.bundlePrefix)
            UserDefaults.standard.synchronize()
            let firstRun3 = UserDefaults.standard.object(forKey: ParseConstants.bundlePrefix) as? String
            XCTAssertNil(firstRun3)
            addCachedResponse()
            ParseSwift.deleteKeychainIfNeeded()
            let storedValue3: String? = try KeychainStore.shared.get(valueFor: key)
            XCTAssertNil(storedValue3)
            guard let firstRun4 = UserDefaults.standard
                    .object(forKey: ParseConstants.bundlePrefix) as? String else {
                        XCTFail("Should have unwrapped")
                        return
                    }
            XCTAssertEqual(firstRun4, ParseConstants.bundlePrefix)

            guard let currentCache = URLSession.parse.configuration.urlCache else {
                XCTFail("Should have unwrapped")
                return
            }
            XCTAssertTrue(currentCache.currentMemoryUsage == 0)
        } catch {
            XCTFail("\(error)")
        }
    }*/
    #endif

    func testCreateParseInstallationOnInit() async throws {
        guard let url = URL(string: "http://localhost:1337/parse") else {
            XCTFail("Should create valid URL")
            return
        }

        try await ParseSwift.initialize(applicationId: "applicationId",
                                        clientKey: "clientKey",
                                        primaryKey: "primaryKey",
                                        serverURL: url,
                                        testing: true) { (_, credential) in
            credential(.performDefaultHandling, nil)
        }

        let currentInstallation = try await Installation.current()

        // Should be in Keychain
        let memoryInstallation: CurrentInstallationContainer<Installation>?
            = try await ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentInstallation)
        XCTAssertEqual(memoryInstallation?.currentInstallation, currentInstallation)

        #if !os(Linux) && !os(Android) && !os(Windows)
        // Should be in Keychain
        let keychainInstallation: CurrentInstallationContainer<Installation>?
            = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation)
        XCTAssertEqual(keychainInstallation?.currentInstallation, currentInstallation)
        #endif
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func testFetchMissingCurrentInstallation() async throws {
        let memory = InMemoryPrimitiveStore()
        await ParseStorage.shared.use(memory)
        await pretendToBeInitialized()
        let installationId = "testMe"
        let badContainer = CurrentInstallationContainer<Installation>(currentInstallation: nil,
                                                                      installationId: installationId)
        await Installation.setCurrentContainer(badContainer)
        try await ParseVersion.setCurrent(try ParseVersion(string: ParseConstants.version))

        var foundInstallation = Installation()
        foundInstallation.updateAutomaticInfo()
        foundInstallation.objectId = "yarr"
        foundInstallation.installationId = installationId

        let results = QueryResponse<Installation>(results: [foundInstallation], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let nanoSeconds = UInt64(1 * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoSeconds)

        guard let url = URL(string: "http://localhost:1337/parse") else {
            XCTFail("Should create valid URL")
            return
        }

        try? await ParseSwift.initialize(applicationId: "applicationId",
                                         clientKey: "clientKey",
                                         primaryKey: "primaryKey",
                                         serverURL: url,
                                         primitiveStore: memory,
                                         testing: true)

        let currentInstallation = try await Installation.current()

        XCTAssertEqual(currentInstallation.installationId, installationId)

        // Should be in Keychain
        let memoryInstallation: CurrentInstallationContainer<Installation>?
            = try await ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentInstallation)
        XCTAssertEqual(memoryInstallation?.currentInstallation, currentInstallation)

        // Should be in Keychain
        let keychainInstallation: CurrentInstallationContainer<Installation>?
            = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation)
        XCTAssertEqual(keychainInstallation?.currentInstallation, currentInstallation)
        MockURLProtocol.removeAll()
    }
    #endif

    func testUpdateAuthChallenge() async throws {
        guard let url = URL(string: "http://localhost:1337/parse") else {
            XCTFail("Should create valid URL")
            return
        }

        try await ParseSwift.initialize(applicationId: "applicationId",
                                        clientKey: "clientKey",
                                        primaryKey: "primaryKey",
                                        serverURL: url,
                                        testing: true) { (_, credential) in
            credential(.performDefaultHandling, nil)
        }
        XCTAssertNotNil(Parse.sessionDelegate.authentication)
        ParseSwift.updateAuthentication(nil)
        XCTAssertNil(Parse.sessionDelegate.authentication)
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func testDontOverwriteMigratedInstallation() async throws {
        guard let url = URL(string: "http://localhost:1337/parse") else {
            XCTFail("Should create valid URL")
            return
        }
        await KeychainStore.createShared()
        let memory = InMemoryPrimitiveStore()
        await ParseStorage.shared.use(memory)
        await pretendToBeInitialized()
        var newInstallation = Installation()
        newInstallation.updateAutomaticInfo()
        newInstallation.objectId = "yarr"
        newInstallation.installationId = UUID().uuidString.lowercased()
        await Installation.setCurrent(newInstallation)

        try await ParseSwift.initialize(applicationId: "applicationId",
                                        clientKey: "clientKey",
                                        primaryKey: "primaryKey",
                                        serverURL: url,
                                        primitiveStore: memory,
                                        testing: true)
        let installation = try await Installation.current()
        XCTAssertTrue(installation.hasSameObjectId(as: newInstallation))
        XCTAssertTrue(installation.hasSameInstallationId(as: newInstallation))
    }

    func testDontOverwriteOldInstallationBecauseVersionLess() async throws {
        guard let url = URL(string: "http://localhost:1337/parse") else {
            XCTFail("Should create valid URL")
            return
        }
        let memory = InMemoryPrimitiveStore()
        await ParseStorage.shared.use(memory)
        await pretendToBeInitialized()
        try await ParseVersion.setCurrent(try ParseVersion(string: "0.0.0"))
        var newInstallation = Installation()
        newInstallation.updateAutomaticInfo()
        newInstallation.installationId = UUID().uuidString.lowercased()
        await Installation.setCurrent(newInstallation)

        XCTAssertNil(newInstallation.objectId)
        let oldInstallation = try await Installation.current()
        XCTAssertTrue(oldInstallation.hasSameInstallationId(as: newInstallation))

        try await ParseSwift.initialize(applicationId: "applicationId",
                                        clientKey: "clientKey",
                                        primaryKey: "primaryKey",
                                        serverURL: url,
                                        primitiveStore: memory,
                                        testing: true)
        let installation = try await Installation.current()
        XCTAssertTrue(installation.hasSameInstallationId(as: newInstallation))
        let currentVersion = try await ParseVersion.current()
        XCTAssertEqual(currentVersion.description, ParseConstants.version)
    }

    func testDontOverwriteOldInstallationBecauseVersionEqual() async throws {
        guard let url = URL(string: "http://localhost:1337/parse") else {
            XCTFail("Should create valid URL")
            return
        }
        let memory = InMemoryPrimitiveStore()
        await ParseStorage.shared.use(memory)
        await pretendToBeInitialized()
        try await ParseVersion.setCurrent(try ParseVersion(string: ParseConstants.version))
        var newInstallation = Installation()
        newInstallation.updateAutomaticInfo()
        newInstallation.installationId = UUID().uuidString.lowercased()
        await Installation.setCurrent(newInstallation)

        XCTAssertNil(newInstallation.objectId)
        let oldInstallation = try await Installation.current()
        XCTAssertTrue(oldInstallation.hasSameInstallationId(as: newInstallation))

        try await ParseSwift.initialize(applicationId: "applicationId",
                                        clientKey: "clientKey",
                                        primaryKey: "primaryKey",
                                        serverURL: url,
                                        primitiveStore: memory,
                                        testing: true)
        let installation = try await Installation.current()
        XCTAssertTrue(installation.hasSameInstallationId(as: newInstallation))
        let currentVersion = try await ParseVersion.current()
        XCTAssertEqual(currentVersion, try ParseVersion(string: ParseConstants.version))
    }

    func testDontOverwriteOldInstallationBecauseVersionGreater() async throws {
        guard let url = URL(string: "http://localhost:1337/parse") else {
            XCTFail("Should create valid URL")
            return
        }
        let memory = InMemoryPrimitiveStore()
        await ParseStorage.shared.use(memory)
        await pretendToBeInitialized()
        let newVersion = "1000.0.0"
        try await ParseVersion.setCurrent(try ParseVersion(string: newVersion))
        var newInstallation = Installation()
        newInstallation.updateAutomaticInfo()
        newInstallation.installationId = UUID().uuidString.lowercased()
        await Installation.setCurrent(newInstallation)

        XCTAssertNil(newInstallation.objectId)
        let oldInstallation = try await Installation.current()
        XCTAssertTrue(oldInstallation.hasSameInstallationId(as: newInstallation))

        try await ParseSwift.initialize(applicationId: "applicationId",
                                        clientKey: "clientKey",
                                        primaryKey: "primaryKey",
                                        serverURL: url,
                                        primitiveStore: memory,
                                        testing: true)
        let installation = try await Installation.current()
        XCTAssertTrue(installation.hasSameInstallationId(as: newInstallation))
        let currentVersion = try await ParseVersion.current()
        XCTAssertEqual(currentVersion.description, newVersion)
    }
    #endif

    func testOverwriteOldInstallation() async throws {
        guard let url = URL(string: "http://localhost:1337/parse") else {
            XCTFail("Should create valid URL")
            return
        }
        let memory = InMemoryPrimitiveStore()
        await ParseStorage.shared.use(memory)
        await pretendToBeInitialized()
        var newInstallation = Installation()
        newInstallation.updateAutomaticInfo()
        newInstallation.installationId = UUID().uuidString.lowercased()
        await Installation.setCurrent(newInstallation)

        XCTAssertNil(newInstallation.objectId)
        let oldInstallation = try await Installation.current()
        XCTAssertTrue(oldInstallation.hasSameInstallationId(as: newInstallation))

        try await ParseSwift.initialize(applicationId: "applicationId",
                                        clientKey: "clientKey",
                                        primaryKey: "primaryKey",
                                        serverURL: url,
                                        primitiveStore: memory,
                                        testing: true)
        let installation = try await Installation.current()
        if !installation.hasSameInstallationId(as: newInstallation) {
            _ = XCTSkip("Should have overwritten installationId")
        }
    }

    func testMigrateObjcKeychainMissing() async throws {
        guard let url = URL(string: "http://localhost:1337/parse") else {
            XCTFail("Should create valid URL")
            return
        }
        try await ParseSwift.initialize(applicationId: "applicationId",
                                        clientKey: "clientKey",
                                        primaryKey: "primaryKey",
                                        serverURL: url,
                                        migratingFromObjcSDK: true,
                                        testing: true)
        let installation = try await Installation.current()
        XCTAssertNotNil(installation.installationId)
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func testMigrateOldKeychainToNew() async throws {
        await KeychainStore.createOld()
        var user = BaseParseUser()
        user.objectId = "wow"
        var userContainer = CurrentUserContainer<BaseParseUser>()
        userContainer.currentUser = user
        userContainer.sessionToken = "session"
        let installationId = "id"
        var installation = Installation()
        installation.installationId = installationId
        installation.objectId = "now"
        installation.updateAutomaticInfo()
        var installationContainer = CurrentInstallationContainer<Installation>()
        installationContainer.currentInstallation = installation
        installationContainer.installationId = installationId
        let config = Config(welcomeMessage: "hello", winningNumber: 5)
        var configContainer = CurrentConfigContainer<Config>()
        configContainer.currentConfig = config
        var acl = ParseACL()
        acl.setReadAccess(objectId: "hello", value: true)
        acl.setReadAccess(objectId: "wow", value: true)
        acl.setWriteAccess(objectId: "wow", value: true)
        let aclContainer = DefaultACL(defaultACL: acl,
                                      lastCurrentUserObjectId: user.objectId,
                                      useCurrentUser: true)
        let version = "1.9.7"
        try await KeychainStore.old.set(version, for: ParseStorage.Keys.currentVersion)
        try await KeychainStore.old.set(userContainer, for: ParseStorage.Keys.currentUser)
        try await KeychainStore.old.set(installationContainer, for: ParseStorage.Keys.currentInstallation)
        try await KeychainStore.old.set(configContainer, for: ParseStorage.Keys.currentConfig)
        try await KeychainStore.old.set(aclContainer, for: ParseStorage.Keys.defaultACL)

        let nanoSeconds = UInt64(1 * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoSeconds)
        guard let url = URL(string: "http://localhost:1337/parse") else {
            XCTFail("Should create valid URL")
            return
        }
        try await ParseSwift.initialize(applicationId: "applicationId",
                                        clientKey: "clientKey",
                                        primaryKey: "primaryKey",
                                        serverURL: url,
                                        testing: true)
        let currentVersion = try await ParseVersion.current()
        XCTAssertEqual(currentVersion.description, ParseConstants.version)
        let currentUser = try await BaseParseUser.current()
        XCTAssertEqual(currentUser, user)
        let currentInstallation = try await Installation.current()
        XCTAssertEqual(currentInstallation, installation)
        let currentConfig = try await Config.current()
        XCTAssertEqual(currentConfig.welcomeMessage, config.welcomeMessage)
        XCTAssertEqual(currentConfig.winningNumber, config.winningNumber)
        let defaultACL = try? await ParseACL.defaultACL()
        XCTAssertEqual(defaultACL, acl)
    }

    func testMigrateObjcSDK() async throws {
        await KeychainStore.createObjectiveC()
        // Set keychain the way objc sets keychain
        guard let objcParseKeychain = KeychainStore.objectiveC else {
            XCTFail("Should have unwrapped")
            return
        }
        let objcInstallationId = "helloWorld"
        _ = await objcParseKeychain.setObjectiveC(object: objcInstallationId, forKey: "installationId")

        guard let url = URL(string: "http://localhost:1337/parse") else {
            XCTFail("Should create valid URL")
            return
        }
        try await ParseSwift.initialize(applicationId: "applicationId",
                                        clientKey: "clientKey",
                                        primaryKey: "primaryKey",
                                        serverURL: url,
                                        migratingFromObjcSDK: true,
                                        testing: true)
        let installation = try await Installation.current()
        XCTAssertEqual(installation.installationId, objcInstallationId)
        let installationContainer = await Installation.currentContainer()
        XCTAssertEqual(installationContainer.installationId, objcInstallationId)
    }

    func testInitializeSDKNoTest() async throws {

        guard let url = URL(string: "http://localhost:1337/parse") else {
            XCTFail("Should create valid URL")
            return
        }
        try await ParseSwift.initialize(applicationId: "applicationId",
                                        clientKey: "clientKey",
                                        primaryKey: "primaryKey",
                                        serverURL: url)
        _ = try await Installation.current()
    }

    func testDeleteObjcSDKKeychain() async throws {
        await KeychainStore.createObjectiveC()
        // Set keychain the way objc sets keychain
        guard let objcParseKeychain = KeychainStore.objectiveC else {
            XCTFail("Should have unwrapped")
            return
        }
        let objcInstallationId = "helloWorld"
        _ = await objcParseKeychain.setObjectiveC(object: objcInstallationId, forKey: "installationId")

        let retrievedInstallationId: String? = await objcParseKeychain.objectObjectiveC(forKey: "installationId")
        XCTAssertEqual(retrievedInstallationId, objcInstallationId)
        do {
            try await ParseSwift.deleteObjectiveCKeychain()
        } catch {
            XCTFail("Should not have thrown error: \(error.localizedDescription)")
        }
        let retrievedInstallationId2: String? = await objcParseKeychain.objectObjectiveC(forKey: "installationId")
        XCTAssertNil(retrievedInstallationId2)

        // This is needed for tear down
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

    func testMigrateObjcSDKMissingInstallation() async throws {
        await KeychainStore.createObjectiveC()

        // Set keychain the way objc sets keychain
        guard let objcParseKeychain = KeychainStore.objectiveC else {
            XCTFail("Should have unwrapped")
            return
        }
        let objcInstallationId = "helloWorld"
        _ = await objcParseKeychain.setObjectiveC(object: objcInstallationId, forKey: "anotherPlace")

        guard let url = URL(string: "http://localhost:1337/parse") else {
            XCTFail("Should create valid URL")
            return
        }
        try await ParseSwift.initialize(applicationId: "applicationId",
                                        clientKey: "clientKey",
                                        primaryKey: "primaryKey",
                                        serverURL: url,
                                        migratingFromObjcSDK: true,
                                        testing: true)
        let installation = try await Installation.current()
        XCTAssertNotNil(installation.installationId)
        let currentInstallationId = await Installation.currentContainer().installationId
        XCTAssertNotNil(currentInstallationId)
        XCTAssertNotEqual(installation.installationId, objcInstallationId)
        XCTAssertNotEqual(currentInstallationId, objcInstallationId)
    }
    #endif
}
