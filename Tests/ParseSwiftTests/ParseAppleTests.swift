//
//  ParseAppleTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/16/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

// swiftlint:disable type_body_length function_body_length

class ParseAppleTests: XCTestCase {
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
        var sessionToken: String?
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

    func testAuthenticationKeys() throws {
        guard let tokenData = "test".data(using: .utf8) else {
            XCTFail("Should have created Data")
            return
        }
        let authData = try ParseApple<User>
            .AuthenticationKeys.id.makeDictionary(user: "testing",
                                                  identityToken: tokenData)
        XCTAssertEqual(authData, ["id": "testing", "token": "test"])
    }

    func testVerifyMandatoryKeys() throws {
        let authData = ["id": "testing", "token": "test"]
        let authDataWrong = ["id": "testing", "hello": "test"]
        XCTAssertTrue(ParseApple<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authData))
        XCTAssertFalse(ParseApple<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authDataWrong))
    }

    func testLogin() async throws {
        var serverResponse = LoginSignupResponse()
        guard let tokenData = "this".data(using: .utf8) else {
            XCTFail("Could not convert token data to string")
            return
        }

        let authData = try ParseApple<User>
            .AuthenticationKeys.id.makeDictionary(user: "testing",
                                                  identityToken: tokenData)
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.apple.__type: authData]
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

        let expectation1 = XCTestExpectation(description: "Login")

        User.apple.login(user: "testing", identityToken: tokenData) { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user, userOnServer)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")

                Task {
                    do {
                        let currentUser = try await User.current()
                        XCTAssertEqual(user, currentUser)
                        var currentLinkedUser = await user.apple.isLinked()
                        XCTAssertTrue(currentLinkedUser)

                        // Test stripping
                        try await user.apple.strip()
                        currentLinkedUser = await user.apple.isLinked()
                        XCTAssertFalse(currentLinkedUser)
                    } catch {
                        XCTFail(error.localizedDescription)
                    }
                    expectation1.fulfill()
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
                expectation1.fulfill()
            }
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLoginAuthData() async throws {
        var serverResponse = LoginSignupResponse()
        guard let tokenData = "this".data(using: .utf8) else {
            XCTFail("Could not convert token data to string")
            return
        }

        let authData = try ParseApple<User>
            .AuthenticationKeys.id.makeDictionary(user: "testing",
                                                  identityToken: tokenData)
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.apple.__type: authData]
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

        let expectation1 = XCTestExpectation(description: "Login")

        User.apple.login(authData: authData) { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user, userOnServer)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                Task {
                    do {
                        let currentUser = try await User.current()
                        XCTAssertEqual(user, currentUser)
                        var currentLinkedUser = await user.apple.isLinked()
                        XCTAssertTrue(currentLinkedUser)

                        // Test stripping
                        try await user.apple.strip()
                        currentLinkedUser = await user.apple.isLinked()
                        XCTAssertFalse(currentLinkedUser)
                    } catch {
                        XCTFail(error.localizedDescription)
                    }
                    expectation1.fulfill()
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
                expectation1.fulfill()
            }
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLoginWrongKeys() async throws {
        _ = try await loginNormally()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Login")

        User.apple.login(authData: ["hello": "world"]) { result in

            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("consisting of keys"))
            } else {
                XCTFail("Should have returned error")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func loginAnonymousUser() async throws {
        let authData = ["id": "yolo"]

        //: Convert the anonymous user to a real new user.
        var serverResponse = LoginSignupResponse()
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.anonymous.__type: authData]
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

        let user = try await User.anonymous.login()
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        XCTAssertEqual(user, userOnServer)
        XCTAssertEqual(user.username, "hello")
        XCTAssertEqual(user.password, "world")
        XCTAssertTrue(ParseAnonymous<User>.isLinked(with: user))
    }

    func testReplaceAnonymousWithApple() async throws {
        try await loginAnonymousUser()
        MockURLProtocol.removeAll()
        guard let tokenData = "this".data(using: .utf8) else {
            XCTFail("Could not convert token data to string")
            return
        }

        let authData = try ParseApple<User>
            .AuthenticationKeys.id.makeDictionary(user: "testing",
                                                  identityToken: tokenData)

        var serverResponse = LoginSignupResponse()
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.apple.__type: authData,
                                   serverResponse.anonymous.__type: nil]
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

        let expectation1 = XCTestExpectation(description: "Login")

        User.apple.login(user: "testing", identityToken: tokenData) { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user.authData, userOnServer.authData)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                XCTAssertFalse(ParseAnonymous<User>.isLinked(with: user))
                Task {
                    do {
                        let currentUser = try await User.current()
                        XCTAssertEqual(user, currentUser)
                        let currentLinkedUser = await user.apple.isLinked()
                        XCTAssertTrue(currentLinkedUser)
                    } catch {
                        XCTFail(error.localizedDescription)
                    }
                    expectation1.fulfill()
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
                expectation1.fulfill()
            }
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testReplaceAnonymousWithLinkedApple() async throws {
        try await loginAnonymousUser()
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

        let expectation1 = XCTestExpectation(description: "Login")

        guard let tokenData = "this".data(using: .utf8) else {
            XCTFail("Could not convert token data to string")
            return
        }

        User.apple.link(user: "testing", identityToken: tokenData) { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                XCTAssertFalse(ParseAnonymous<User>.isLinked(with: user))
                Task {
                    do {
                        let currentUser = try await User.current()
                        XCTAssertEqual(user, currentUser)
                        let currentLinkedUser = await user.apple.isLinked()
                        XCTAssertTrue(currentLinkedUser)
                    } catch {
                        XCTFail(error.localizedDescription)
                    }
                    expectation1.fulfill()
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
                expectation1.fulfill()
            }
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLinkLoggedInUserWithApple() async throws {
        _ = try await loginNormally()
        MockURLProtocol.removeAll()

        var serverResponse = LoginSignupResponse()
        serverResponse.sessionToken = nil
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

        let expectation1 = XCTestExpectation(description: "Login")

        guard let tokenData = "this".data(using: .utf8) else {
            XCTFail("Could not convert token data to string")
            return
        }

        User.apple.link(user: "testing", identityToken: tokenData) { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
                XCTAssertEqual(user.username, "hello10")
                XCTAssertNil(user.password)
                XCTAssertFalse(ParseAnonymous<User>.isLinked(with: user))
                Task {
                    do {
                        let currentUser = try await User.current()
                        XCTAssertEqual(user, currentUser)
                        let currentSessionToken = await currentUser.sessionToken()
                        XCTAssertEqual(currentSessionToken, "myToken")
                        let currentLinkedUser = await user.apple.isLinked()
                        XCTAssertTrue(currentLinkedUser)
                    } catch {
                        XCTFail(error.localizedDescription)
                    }
                    expectation1.fulfill()
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
                expectation1.fulfill()
            }
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLinkLoggedInAuthData() async throws {
        _ = try await loginNormally()
        MockURLProtocol.removeAll()

        var serverResponse = LoginSignupResponse()
        serverResponse.sessionToken = nil
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

        let expectation1 = XCTestExpectation(description: "Login")

        guard let tokenData = "this".data(using: .utf8) else {
            XCTFail("Could not convert token data to string")
            return
        }

        let authData = try ParseApple<User>
            .AuthenticationKeys.id.makeDictionary(user: "testing",
                                                  identityToken: tokenData)

        User.apple.link(authData: authData) { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
                XCTAssertEqual(user.username, "hello10")
                XCTAssertNil(user.password)
                XCTAssertFalse(ParseAnonymous<User>.isLinked(with: user))
                Task {
                    do {
                        let currentUser = try await User.current()
                        XCTAssertEqual(user, currentUser)
                        let currentSessionToken = await currentUser.sessionToken()
                        XCTAssertEqual(currentSessionToken, "myToken")
                        let currentLinkedUser = await user.apple.isLinked()
                        XCTAssertTrue(currentLinkedUser)
                    } catch {
                        XCTFail(error.localizedDescription)
                    }
                    expectation1.fulfill()
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
                expectation1.fulfill()
            }
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLinkLoggedInUserWrongKeys() async throws {
        _ = try await loginNormally()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Login")

        User.apple.link(authData: ["hello": "world"]) { result in

            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("consisting of keys"))
            } else {
                XCTFail("Should have returned error")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testUnlink() async throws {
        _ = try await loginNormally()
        MockURLProtocol.removeAll()
        guard let tokenData = "this".data(using: .utf8) else {
            XCTFail("Could not convert token data to string")
            return
        }

        let authData = try ParseApple<User>
            .AuthenticationKeys.id.makeDictionary(user: "testing",
                                                  identityToken: tokenData)
        var user = try await User.current()
        user.authData = [User.apple.__type: authData]
        try await User.setCurrent(user)
        let isLinkedUser = await User.apple.isLinked()
        XCTAssertTrue(isLinkedUser)

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

        let expectation1 = XCTestExpectation(description: "Login")

        User.apple.unlink { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
                XCTAssertEqual(user.username, "hello10")
                XCTAssertNil(user.password)
                Task {
                    do {
                        let currentUser = try await User.current()
                        XCTAssertEqual(user, currentUser)
                        let currentLinkedUser = await user.apple.isLinked()
                        XCTAssertFalse(currentLinkedUser)
                    } catch {
                        XCTFail(error.localizedDescription)
                    }
                    expectation1.fulfill()
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }
}
