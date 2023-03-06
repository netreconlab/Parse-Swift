//
//  ParseSpotifyCombineTests.swift
//  ParseSwift
//
//  Created by Ulaş Sancak on 06/21/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if canImport(Combine)

import Foundation
import XCTest
import Combine
@testable import ParseSwift

class ParseSpotifyCombineTests: XCTestCase { // swiftlint:disable:this type_body_length

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

    func testLogin() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")
        let expectation2 = XCTestExpectation(description: "Update")

        var serverResponse = LoginSignupResponse()
        let authData = ParseAnonymous<User>.AuthenticationKeys.id.makeDictionary()
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.spotify.__type: authData]
        serverResponse.createdAt = Date()
        serverResponse.updatedAt = serverResponse.createdAt?.addingTimeInterval(+300)

        var userOnServer: User!

        let encoded: Data!
        do {
            encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = User.spotify.loginPublisher(id: "testing", accessToken: "access_token")
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { user in

            XCTAssertEqual(user, userOnServer)
            XCTAssertEqual(user.username, "hello")
            XCTAssertEqual(user.password, "world")

            Task {
                do {
                    let currentUser = try await User.current()
                    XCTAssertEqual(user, currentUser)
                    let isLinkedUser = await user.spotify.isLinked()
                    XCTAssertTrue(isLinkedUser)
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
    func testLoginAuthData() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")
        let expectation2 = XCTestExpectation(description: "Update")

        var serverResponse = LoginSignupResponse()
        let authData = ParseAnonymous<User>.AuthenticationKeys.id.makeDictionary()
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.spotify.__type: authData]
        serverResponse.createdAt = Date()
        serverResponse.updatedAt = serverResponse.createdAt?.addingTimeInterval(+300)

        var userOnServer: User!

        let encoded: Data!
        do {
            encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = User.spotify.loginPublisher(authData: ["id": "testing",
                                                               "access_token": "access_token"])
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { user in

            XCTAssertEqual(user, userOnServer)
            XCTAssertEqual(user.username, "hello")
            XCTAssertEqual(user.password, "world")
            Task {
                do {
                    let currentUser = try await User.current()
                    XCTAssertEqual(user, currentUser)
                    let isLinkedUser = await user.spotify.isLinked()
                    XCTAssertTrue(isLinkedUser)
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

    func loginNormally() async throws -> User {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        return try await User.login(username: "parse", password: "user")
    }

    func testLink() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")
        let expectation2 = XCTestExpectation(description: "Update")

        _ = try await loginNormally()
        MockURLProtocol.removeAll()

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()

        var userOnServer: User!

        let encoded: Data!
        do {
            encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = User.spotify.linkPublisher(id: "testing", accessToken: "access_token")
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { user in

            XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
            XCTAssertEqual(user.username, "hello10")
            XCTAssertNil(user.password)
            XCTAssertFalse(ParseAnonymous<User>.isLinked(with: user))
            Task {
                do {
                    let currentUser = try await User.current()
                    XCTAssertEqual(user, currentUser)
                    let isLinkedUser = await user.spotify.isLinked()
                    XCTAssertTrue(isLinkedUser)
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

    func testLinkAuthData() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")
        let expectation2 = XCTestExpectation(description: "Update")

        _ = try await loginNormally()
        MockURLProtocol.removeAll()

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()

        var userOnServer: User!

        let encoded: Data!
        do {
            encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = User.spotify.linkPublisher(authData: ["id": "testing",
                                                              "access_token": "access_token"])
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { user in

            XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
            XCTAssertEqual(user.username, "hello10")
            XCTAssertNil(user.password)
            XCTAssertFalse(ParseAnonymous<User>.isLinked(with: user))
            Task {
                do {
                    let currentUser = try await User.current()
                    XCTAssertEqual(user, currentUser)
                    let isLinkedUser = await user.spotify.isLinked()
                    XCTAssertTrue(isLinkedUser)
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
    func testUnlink() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")
        let expectation2 = XCTestExpectation(description: "Update")

        var user = try await loginNormally()
        MockURLProtocol.removeAll()

        let authData = ParseSpotify<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "access_token")
        user.authData = [User.spotify.__type: authData]
        try await User.setCurrent(user)
        XCTAssertTrue(ParseSpotify.isLinked(with: user))

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()

        var userOnServer: User!

        let encoded: Data!
        do {
            encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = User.spotify.unlinkPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { user in

            XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
            XCTAssertEqual(user.username, "hello10")
            XCTAssertNil(user.password)
            Task {
                do {
                    let currentUser = try await User.current()
                    XCTAssertEqual(user, currentUser)
                    let isLinkedUser = await user.spotify.isLinked()
                    XCTAssertFalse(isLinkedUser)
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
    func testUnlinkPassUser() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")
        let expectation2 = XCTestExpectation(description: "Update")

        var user = try await loginNormally()
        MockURLProtocol.removeAll()

        let authData = ParseSpotify<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "access_token")
        user.authData = [User.spotify.__type: authData]
        try await User.setCurrent(user)
        XCTAssertTrue(ParseSpotify.isLinked(with: user))

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()

        var userOnServer: User!

        let encoded: Data!
        do {
            encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = User.spotify.unlinkPublisher(user)
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { user in

            XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
            XCTAssertEqual(user.username, "hello10")
            XCTAssertNil(user.password)
            Task {
                do {
                    let currentUser = try await User.current()
                    XCTAssertEqual(user, currentUser)
                    let isLinkedUser = await user.spotify.isLinked()
                    XCTAssertFalse(isLinkedUser)
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
