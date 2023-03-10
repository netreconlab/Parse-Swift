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

class ParseConfigCodableTests: XCTestCase { // swiftlint:disable:this type_body_length

    struct Config: ParseConfig {
        var welcomeMessage: String?
        var winningNumber: Int?
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
        #if !os(Linux) && !os(Android) && !os(Windows)
        try await KeychainStore.shared.deleteAll()
        #endif
        try await ParseStorage.shared.deleteAll()
    }

    func userLogin() async {
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
        do {
            _ = try await User.login(username: loginUserName, password: loginPassword)
            MockURLProtocol.removeAll()
        } catch {
            XCTFail("Should login")
        }
    }

    func testUpdateKeyChainIfNeeded() async throws {
        await userLogin()
        let config = Config()
        do {
            _ = try await Config.current()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.containedIn([.otherCause]))
        }

        await Config.updateKeychainIfNeeded(config, deleting: true)
        do {
            _ = try await Config.current()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.containedIn([.otherCause]))
        }
    }

    func testDeleteFromKeychainOnLogout() async throws {
        await userLogin()
        var config = Config()
        config.welcomeMessage = "Hello"
        do {
            _ = try await Config.current()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.containedIn([.otherCause]))
        }

        await Config.updateKeychainIfNeeded(config)

        let currentConfig = try await Config.current()
        XCTAssertEqual(config.welcomeMessage, currentConfig.welcomeMessage)

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
            _ = try await Config.current()
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

    func testEncoding() throws {
        var configDictionary = [String: AnyCodable]()
        configDictionary["welcomeMessage"] = AnyCodable("Hello")
        let expected = "{\"welcomeMessage\":\"Hello\"}"
        let encoded = try ParseCoding.jsonEncoder().encode(configDictionary)
        let decoded = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(decoded, expected)
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
        
        // Test deletingKeychain
    }

    func testCanSetParseConfig() async throws {
        let key = "welcomeMessage"
        let value = "Hello"
        var configDictionary = [String: AnyCodable]()
        configDictionary[key] = AnyCodable(value)
        await ParseConfigCodable.setCurrent(configDictionary)

        let configFromKeychain = try await Config.current()
        var config = Config()
        config.welcomeMessage = "Hello"
        XCTAssertEqual(configFromKeychain, config)
    }

    func testFetch() async throws {
        await userLogin()
        let config = Config()

        var configOnServer = config
        configOnServer.welcomeMessage = "Hello"
        let serverResponse = ConfigFetchResponse(params: configOnServer)
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
        do {
            let fetched = try await config.fetch()
            XCTAssertEqual(fetched.welcomeMessage, configOnServer.welcomeMessage)
            let currentConfig = try await Config.current()
            XCTAssertEqual(currentConfig.welcomeMessage, configOnServer.welcomeMessage)

            #if !os(Linux) && !os(Android) && !os(Windows)
            // Should be updated in Keychain
            guard let keychainConfig: CurrentConfigContainer<Config>?
                = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig) else {
                    XCTFail("Should get object from Keychain")
                return
            }
            XCTAssertEqual(keychainConfig?.currentConfig?.welcomeMessage, configOnServer.welcomeMessage)
            #endif

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testFetchAsync() async throws {
        await userLogin()
        let config = Config()

        var configOnServer = config
        configOnServer.welcomeMessage = "Hello"
        let serverResponse = ConfigFetchResponse(params: configOnServer)
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

        let expectation = XCTestExpectation(description: "Config save")
        config.fetch { result in
            switch result {

            case .success(let fetched):
                XCTAssertEqual(fetched.welcomeMessage, configOnServer.welcomeMessage)
                let immutableConfigOnServer = configOnServer
                Task {
                    let currentConfig = try await Config.current()
                    XCTAssertEqual(currentConfig.welcomeMessage, immutableConfigOnServer.welcomeMessage)

                    #if !os(Linux) && !os(Android) && !os(Windows)
                    // Should be updated in Keychain
                    let keychainConfig: CurrentConfigContainer<Config>?
                    = try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig)
                    XCTAssertEqual(keychainConfig?.currentConfig?.welcomeMessage,
                                   immutableConfigOnServer.welcomeMessage)
                    #endif
                    expectation.fulfill()
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 10.0)
    }

    func testUpdateCommand() async throws {
        var config = Config()
        config.welcomeMessage = "Hello"
        let command = await config.updateCommand()
        XCTAssertEqual(command.path.urlComponent, "/config")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNotNil(command.body)
    }

    func testSave() async throws {
        await userLogin()
        var config = Config()
        config.welcomeMessage = "Hello"

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
        do {
            let saved = try await config.save()
            let currentConfig = try await Config.current()
            XCTAssertTrue(saved)
            XCTAssertEqual(currentConfig.welcomeMessage, config.welcomeMessage)

            #if !os(Linux) && !os(Android) && !os(Windows)
            // Should be updated in Keychain
            guard let keychainConfig: CurrentConfigContainer<Config>
                = try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig) else {
                    XCTFail("Should get object from Keychain")
                return
            }
            XCTAssertEqual(keychainConfig.currentConfig?.welcomeMessage, config.welcomeMessage)
            #endif
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveAsync() async throws {
        await userLogin()
        var config = Config()
        config.welcomeMessage = "Hello"

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

        let expectation = XCTestExpectation(description: "Config save")
        config.save { result in
            switch result {

            case .success(let saved):
                XCTAssertTrue(saved)
                let immutableConfig = config
                Task {
                    let currentConfig = try await Config.current()
                    XCTAssertEqual(currentConfig.welcomeMessage, immutableConfig.welcomeMessage)

                    #if !os(Linux) && !os(Android) && !os(Windows)
                    // Should be updated in Keychain
                    let keychainConfig: CurrentConfigContainer<Config>?
                        = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig)
                    XCTAssertEqual(keychainConfig?.currentConfig?.welcomeMessage, immutableConfig.welcomeMessage)
                    #endif
                    expectation.fulfill()
                }

            case .failure(let error):
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 10.0)
    }
}
