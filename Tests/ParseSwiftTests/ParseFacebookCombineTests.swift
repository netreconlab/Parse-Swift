//
//  ParseFacebookCombineTests.swift
//  ParseSwift
//
//  Created by Abdulaziz Alhomaidhi on 3/19/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
import Combine
@testable import ParseSwift

// swiftlint:disable type_body_length function_body_length

class ParseFacebookCombineTests: XCTestCase {

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

    @MainActor
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

    func testLimitedLogin() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")
        let expectation2 = XCTestExpectation(description: "Update")
        var serverResponse = LoginSignupResponse()
        let authData = ParseAnonymous<User>.AuthenticationKeys.id.makeDictionary()
        serverResponse.username = "hello"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.facebook.__type: authData]
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

        let publisher = User.facebook.loginPublisher(userId: "testing",
                                                     authenticationToken: "authenticationToken")
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                }
                expectation1.fulfill()

        }, receiveValue: { user in

            XCTAssertEqual(user, userOnServer)
            XCTAssertEqual(user.username, "hello")
            XCTAssertNil(user.password)
            Task {
                do {
                    let currentUser = try await User.current()
                    XCTAssertEqual(user, currentUser)
                    let isLinkedUser = await user.facebook.isLinked()
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

    func testGraphAPILogin() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")
        let expectation2 = XCTestExpectation(description: "Update")
        var serverResponse = LoginSignupResponse()
        let authData = ParseAnonymous<User>.AuthenticationKeys.id.makeDictionary()
        serverResponse.username = "hello"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.facebook.__type: authData]
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

        let publisher = User.facebook.loginPublisher(userId: "testing", accessToken: "accessToken")
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                }
                expectation1.fulfill()

        }, receiveValue: { user in

            XCTAssertEqual(user, userOnServer)
            XCTAssertEqual(user.username, "hello")
            XCTAssertNil(user.password)
            Task {
                do {
                    let currentUser = try await User.current()
                    XCTAssertEqual(user, currentUser)
                    let isLinkedUser = await user.facebook.isLinked()
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

    func testLoginAuthData() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")
        let expectation2 = XCTestExpectation(description: "Update")
        var serverResponse = LoginSignupResponse()
        let authData = ParseAnonymous<User>.AuthenticationKeys.id.makeDictionary()
        serverResponse.username = "hello"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.facebook.__type: authData]
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

        let faceookAuthData = ParseFacebook<User>
            .AuthenticationKeys.id.makeDictionary(userId: "testing",
                                                  accessToken: "accessToken",
                                                  authenticationToken: nil)

        let publisher = User.facebook.loginPublisher(authData: faceookAuthData)
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                }
                expectation1.fulfill()

        }, receiveValue: { user in

            XCTAssertEqual(user, userOnServer)
            XCTAssertEqual(user.username, "hello")
            XCTAssertNil(user.password)
            Task {
                do {
                    let currentUser = try await User.current()
                    XCTAssertEqual(user, currentUser)
                    let isLinkedUser = await user.facebook.isLinked()
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

        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows)
        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1, expectation2], timeout: 20.0)
        #endif
    }

    func testLinkLimitedLogin() async throws {
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

        let publisher = User.facebook.linkPublisher(userId: "testing", authenticationToken: "authenticationToken")
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
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
                    let isLinkedUser = await user.facebook.isLinked()
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

        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows)
        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1, expectation2], timeout: 20.0)
        #endif
    }

    func testLinkGraphAPILogin() async throws {
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

        let publisher = User.facebook.linkPublisher(userId: "testing",
                                                    accessToken: "accessToken")
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
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
                    let isLinkedUser = await user.facebook.isLinked()
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

        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows)
        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1, expectation2], timeout: 20.0)
        #endif
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

        let authData = ParseFacebook<User>
            .AuthenticationKeys.id.makeDictionary(userId: "testing",
                                                  accessToken: "accessToken",
                                                  authenticationToken: nil)

        let publisher = User.facebook.linkPublisher(authData: authData)
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
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
                    let isLinkedUser = await user.facebook.isLinked()
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

        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows)
        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1, expectation2], timeout: 20.0)
        #endif
    }

    func testUnlinkLimitedLogin() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")
        let expectation2 = XCTestExpectation(description: "Update")
        _ = try await loginNormally()
        MockURLProtocol.removeAll()

        let authData = ParseFacebook<User>
            .AuthenticationKeys.id.makeDictionary(userId: "testing",
                                                  accessToken: nil,
                                                  authenticationToken: "authenticationToken")
        var user = try await User.current()
        user.authData = [User.facebook.__type: authData]
        try await User.setCurrent(user)
        let isLinked = await User.facebook.isLinked()
        XCTAssertTrue(isLinked)

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

        let publisher = User.facebook.unlinkPublisher(user)
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
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
                    let isLinkedUser = await user.facebook.isLinked()
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

        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows)
        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1, expectation2], timeout: 20.0)
        #endif
    }

    func testUnlinkGraphAPILogin() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")
        let expectation2 = XCTestExpectation(description: "Update")
        _ = try await loginNormally()
        MockURLProtocol.removeAll()

        let authData = ParseFacebook<User>
            .AuthenticationKeys.id.makeDictionary(userId: "testing",
                                                  accessToken: "accessToken",
                                                  authenticationToken: nil)
        var user = try await User.current()
        user.authData = [User.facebook.__type: authData]
        try await User.setCurrent(user)
        let isLinked = await User.facebook.isLinked()
        XCTAssertTrue(isLinked)

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

        let publisher = User.facebook.unlinkPublisher(user)
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
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
                    let isLinkedUser = await user.facebook.isLinked()
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

        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows)
        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1, expectation2], timeout: 20.0)
        #endif
    }
}

#endif
