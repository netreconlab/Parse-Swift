//
//  ParseConfigCodableCombineTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 3/10/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)

import Foundation
import XCTest
import Combine
@testable import ParseSwift

class ParseConfigCodableCombineTests: XCTestCase {

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

    // swiftlint:disable:next function_body_length
    func testFetch() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")
        let expectation2 = XCTestExpectation(description: "Update")

        await userLogin()
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

        let publisher = ParseConfigCodable<AnyCodable>.fetchPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                }
                expectation1.fulfill()

            }, receiveValue: { fetched in

            guard let fetchedValue = fetched[key]?.value as? String else {
                XCTFail("Should have unwrapped")
                return
            }
            XCTAssertEqual(fetchedValue, value)

            Task {
                do {
                    let configCodable: [String: AnyCodable] = try await ParseConfigCodable.current()
                    guard let codableValue = configCodable[key]?.value as? String else {
                        XCTFail("Should have unwrapped")
                        return
                    }
                    XCTAssertEqual(codableValue, value)

                    #if !os(Linux) && !os(Android) && !os(Windows)
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
                } catch {
                    XCTFail(error.localizedDescription)
                }
                DispatchQueue.main.async {
                    expectation2.fulfill()
                }
            }
        })
        publisher.store(in: &current)

        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    // swiftlint:disable:next function_body_length
    func testSave() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")
        let expectation2 = XCTestExpectation(description: "Update")

        await userLogin()

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

        let publisher = ParseConfigCodable.savePublisher(config)
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

            Task {

                do {
                    let configCodable: [String: AnyCodable] = try await ParseConfigCodable.current()
                    guard let codableValue = configCodable[key]?.value as? String else {
                        XCTFail("Should have unwrapped")
                        return
                    }
                    XCTAssertEqual(codableValue, value)

                    #if !os(Linux) && !os(Android) && !os(Windows)
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
                } catch {
                    XCTFail(error.localizedDescription)
                }
                DispatchQueue.main.async {
                    expectation2.fulfill()
                }
            }
        })
        publisher.store(in: &current)
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }
}

#endif
