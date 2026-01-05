//
//  ParseConfigCombineTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/30/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)

import Foundation
import XCTest
import Combine
@testable import ParseSwift

class ParseConfigCombineTests: XCTestCase, @unchecked Sendable {

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

    // swiftlint:disable:next function_body_length
    func testFetch() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")
        let expectation2 = XCTestExpectation(description: "Update")

        try await userLogin()
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

        let publisher = config.fetchPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                }
                expectation1.fulfill()

        }, receiveValue: { fetched in

            XCTAssertEqual(fetched.welcomeMessage, configOnServer.welcomeMessage)
            let config = configOnServer
            Task {
                do {
                    let current = try await Config.current()
                    XCTAssertEqual(current.welcomeMessage, config.welcomeMessage)

                    #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
                    // Should be updated in Keychain
                    let keychainConfig: CurrentConfigContainer<Config>?
                        = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig)
                    XCTAssertEqual(keychainConfig?.currentConfig?.welcomeMessage, config.welcomeMessage)
                    #endif
                } catch {
                    XCTFail(error.localizedDescription)
                }
                DispatchQueue.main.async {
                    expectation2.fulfill()
                }
            }
        })
        publisher.store(in: &current)

        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1, expectation2], timeout: 20.0)
        #endif
    }

    // swiftlint:disable:next function_body_length
    func testSave() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")
        let expectation2 = XCTestExpectation(description: "Update")

        try await userLogin()
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

        let publisher = config.savePublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                }
                expectation1.fulfill()

        }, receiveValue: { saved in

            XCTAssertTrue(saved)
            let immutableConfig = config
            Task {
                do {
                    let current = try await Config.current()
                    XCTAssertEqual(current.welcomeMessage, immutableConfig.welcomeMessage)

                    #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
                    // Should be updated in Keychain
                    let keychainConfig: CurrentConfigContainer<Config>?
                        = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig)
                    XCTAssertEqual(keychainConfig?.currentConfig?.welcomeMessage, immutableConfig.welcomeMessage)
                    #endif
                } catch {
                    XCTFail(error.localizedDescription)
                }
                DispatchQueue.main.async {
                    expectation2.fulfill()
                }
            }
        })
        publisher.store(in: &current)
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1, expectation2], timeout: 20.0)
        #endif
    }
}

#endif
