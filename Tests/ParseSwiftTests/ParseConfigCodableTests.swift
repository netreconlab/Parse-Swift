//
//  ParseConfigCodableTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 3/10/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseConfigCodableTests: XCTestCase, @unchecked Sendable { // swiftlint:disable:this type_body_length

    struct Config: ParseConfig {
        var welcomeMessage: String?
    }

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

    func userLogin() async throws {
        let loginResponse = LoginSignupResponse()
        let loginUserName = "hello10"
        let loginPassword = "world"

        let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
        MockURLProtocol.mockRequests { _ in
			MockURLResponse(data: encoded, statusCode: 200)
        }
        do {
            _ = try await User.login(username: loginUserName, password: loginPassword)
            MockURLProtocol.removeAll()
        } catch {
            XCTFail("Should login")
        }
    }

    func testUpdateStorageIfNeeded() async throws {
        try await userLogin()
        let key = "welcomeMessage"
        let value = "Hello"
        var configDictionary = [String: AnyCodable]()
        configDictionary[key] = AnyCodable(value)

        do {
            _ = try await ParseConfigCodable<[String: AnyCodable]>.current()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.containedIn([.otherCause]))
        }

        await ParseConfigCodable.updateStorageIfNeeded(configDictionary, deleting: true)
        do {
            _ = try await ParseConfigCodable<[String: AnyCodable]>.current()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.containedIn([.otherCause]))
        }
    }

    func testDeleteFromStorageOnLogout() async throws {
        try await userLogin()
        let key = "welcomeMessage"
        let value = "Hello"
        var configDictionary = [String: AnyCodable]()
        configDictionary[key] = AnyCodable(value)

        do {
            _ = try await ParseConfigCodable<[String: AnyCodable]>.current()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.containedIn([.otherCause]))
        }

        await ParseConfigCodable.setCurrent(configDictionary)

        let configCodable: [String: AnyCodable] = try await ParseConfigCodable.current()
        guard let codableValue = configCodable[key]?.value as? String else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertEqual(codableValue, value)

        let logoutResponse = NoBody()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(logoutResponse)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        try await User.logout()
        do {
            _ = try await ParseConfigCodable<[String: AnyCodable]>.current()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.containedIn([.otherCause]))
        }
    }

    func testFetchCommand() async throws {
        var configDictionary = [String: AnyCodable]()
        configDictionary["welcomeMessage"] = AnyCodable("Hello")
        let command = await ParseConfigCodable<[String: AnyCodable]>.fetchCommand()
        XCTAssertEqual(command.path.urlComponent, "/config")
        XCTAssertEqual(command.method, API.Method.GET)
        XCTAssertNil(command.body)
    }

    func testUpdateCommand() async throws {
        var configDictionary = [String: AnyCodable]()
        configDictionary["welcomeMessage"] = AnyCodable("Hello")
        let command = await ParseConfigCodable.updateCommand(configDictionary)
        XCTAssertEqual(command.path.urlComponent, "/config")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNotNil(command.body)
    }

    func testCanRetrieveFromParseConfig() async throws {
        let key = "welcomeMessage"
        let value = "Hello"
        var config = Config()
        config.welcomeMessage = "Hello"
        await Config.setCurrent(config)
        let configCodable: [String: AnyCodable] = try await ParseConfigCodable.current()
        guard let codableValue = configCodable[key]?.value as? String else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertEqual(codableValue, value)
    }

    func testCanSetParseConfig() async throws {
        let key = "welcomeMessage"
        let value = "Hello"
        var configDictionary = [String: AnyCodable]()
        configDictionary[key] = AnyCodable(value)
        await ParseConfigCodable.setCurrent(configDictionary)

        let configFromStorage = try await Config.current()
        var config = Config()
        config.welcomeMessage = "Hello"
        XCTAssertEqual(configFromStorage, config)
    }

    func testFetch() async throws {
        try await userLogin()

        let key = "welcomeMessage"
        let value = "Hello"
        var configOnServer = [String: AnyCodable]()
        configOnServer[key] = AnyCodable(value)

        let serverResponse = ConfigCodableFetchResponse(params: configOnServer)
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let fetched: [String: AnyCodable] = try await ParseConfigCodable.fetch()

        guard let fetchedValue = fetched[key]?.value as? String else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertEqual(fetchedValue, value)

        let configCodable: [String: AnyCodable] = try await ParseConfigCodable.current()
        guard let codableValue = configCodable[key]?.value as? String else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertEqual(codableValue, value)

        #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        // Should be updated in Keychain
        guard let keychainConfig: CurrentConfigDictionaryContainer<AnyCodable>?
            = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig) else {
                XCTFail("Should get object from Keychain")
            return
        }
        guard let keychainValue = keychainConfig?.currentConfig?[key]?.value as? String else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertEqual(codableValue, keychainValue)
        #endif
    }

    func testSave() async throws {
        try await userLogin()

        let serverResponse = BooleanResponse(result: true)
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let key = "welcomeMessage"
        let value = "Hello"
        var config = [String: AnyCodable]()
        config[key] = AnyCodable(value)

        let saved = try await ParseConfigCodable.save(config)
        XCTAssertTrue(saved)
        let configCodable: [String: AnyCodable] = try await ParseConfigCodable.current()
        guard let codableValue = configCodable[key]?.value as? String else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertEqual(codableValue, value)

        #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        // Should be updated in Keychain
        guard let keychainConfig: CurrentConfigDictionaryContainer<AnyCodable>?
            = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig) else {
                XCTFail("Should get object from Keychain")
            return
        }
        guard let keychainValue = keychainConfig?.currentConfig?[key]?.value as? String else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertEqual(codableValue, keychainValue)
        #endif
    }
}
