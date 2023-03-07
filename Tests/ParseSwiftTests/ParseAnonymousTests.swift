//
//  ParseAnonymousTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/16/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

// swiftlint:disable type_body_length

class ParseAnonymousTests: XCTestCase {

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

    struct UpdateSessionTokenResponse: Codable {
        var updatedAt: Date
        let sessionToken: String?
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

    func testStrip() throws {

        let expectedAuth = ["id": "yolo"]
        var user = User()
        user.authData = [user.anonymous.__type: expectedAuth]
        XCTAssertEqual(user.authData, ["anonymous": expectedAuth])
        let strippedAuth = user.anonymous.strip(user)
        XCTAssertEqual(strippedAuth.authData, ["anonymous": nil])

    }

    func testAuthenticationKeys() throws {
        let authData = ParseAnonymous<User>.AuthenticationKeys.id.makeDictionary()
        XCTAssertEqual(Array(authData.keys), ["id"])
        XCTAssertNotNil(authData["id"])
        XCTAssertNotEqual(authData["id"], "")
        XCTAssertNotEqual(authData["id"], "12345")
    }

    func testLogin() async throws {
        var serverResponse = LoginSignupResponse()
        let authData = ParseAnonymous<User>.AuthenticationKeys.id.makeDictionary()
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

        let login1 = try await User.anonymous.login()
        let currentUser = try await User.current()
        XCTAssertEqual(login1, currentUser)
        XCTAssertEqual(login1, userOnServer)
        XCTAssertEqual(login1.username, "hello")
        XCTAssertEqual(login1.password, "world")
        let isLinked = await login1.anonymous.isLinked()
        XCTAssertTrue(isLinked)
    }

    func testLoginAuthData() async throws {
        var serverResponse = LoginSignupResponse()
        let authData = ParseAnonymous<User>.AuthenticationKeys.id.makeDictionary()
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

        let login1 = try await User.anonymous.login(authData: .init())
        let currentUser = try await User.current()
        XCTAssertEqual(login1, currentUser)
        XCTAssertEqual(login1, userOnServer)
        XCTAssertEqual(login1.username, "hello")
        XCTAssertEqual(login1.password, "world")
        XCTAssertTrue(ParseAnonymous<User>.isLinked(with: login1))
    }

    func testLoginAsync() throws {
        var serverResponse = LoginSignupResponse()
        let authData = ParseAnonymous<User>.AuthenticationKeys.id.makeDictionary()
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

        let expectation1 = XCTestExpectation(description: "Login")

        User.anonymous.login { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user, userOnServer)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                XCTAssertTrue(ParseAnonymous<User>.isLinked(with: user))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLoginAuthDataAsync() throws {
        var serverResponse = LoginSignupResponse()
        let authData = ParseAnonymous<User>.AuthenticationKeys.id.makeDictionary()
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

        let expectation1 = XCTestExpectation(description: "Login")

        User.anonymous.login(authData: .init()) { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user, userOnServer)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                XCTAssertTrue(ParseAnonymous<User>.isLinked(with: user))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testReplaceAnonymousUser() async throws {
        try await testLogin()
        let user = try await User.current()
        guard let updatedAt = user.updatedAt else {
            XCTFail("Shold have unwrapped")
            return
        }
        XCTAssertTrue(ParseAnonymous<User>.isLinked(with: user))

        var response = UpdateSessionTokenResponse(updatedAt: updatedAt.addingTimeInterval(+300),
            sessionToken: "blast")

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(response)
            // Get dates in correct format from ParseDecoding strategy
            response = try ParseCoding.jsonDecoder().decode(UpdateSessionTokenResponse.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.removeAll()
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let expectation1 = XCTestExpectation(description: "Login")

        var current = try await User.current()
        current.username = "hello"
        current.password = "world"
        current.signup { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                XCTAssertFalse(ParseAnonymous<User>.isLinked(with: user))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testReplaceAnonymousUserBody() async throws {
        try await testLogin()
        let user = try await User.current()
        guard let updatedAt = user.updatedAt else {
            XCTFail("Shold have unwrapped")
            return
        }
        XCTAssertTrue(ParseAnonymous<User>.isLinked(with: user))

        var response = UpdateSessionTokenResponse(updatedAt: updatedAt.addingTimeInterval(+300),
            sessionToken: "blast")

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(response)
            // Get dates in correct format from ParseDecoding strategy
            response = try ParseCoding.jsonDecoder().decode(UpdateSessionTokenResponse.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.removeAll()
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let expectation1 = XCTestExpectation(description: "Login")

        User.signup(username: "hello",
                    password: "world") { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                XCTAssertFalse(ParseAnonymous<User>.isLinked(with: user))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testReplaceAnonymousUserSync() async throws {
        try await testLogin()
        var user = try await User.current()
        guard let updatedAt = user.updatedAt else {
            XCTFail("Shold have unwrapped")
            return
        }
        XCTAssertTrue(ParseAnonymous<User>.isLinked(with: user))

        var response = UpdateSessionTokenResponse(updatedAt: updatedAt.addingTimeInterval(+300),
            sessionToken: "blast")

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(response)
            // Get dates in correct format from ParseDecoding strategy
            response = try ParseCoding.jsonDecoder().decode(UpdateSessionTokenResponse.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.removeAll()
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        user.username = "hello"
        user.password = "world"
        let signedInUser = try await user.signup()
        let currentUser = try await User.current()
        XCTAssertEqual(signedInUser, currentUser)
        XCTAssertEqual(signedInUser.username, "hello")
        XCTAssertEqual(signedInUser.password, "world")
        XCTAssertFalse(ParseAnonymous<User>.isLinked(with: signedInUser))
    }

    func testReplaceAnonymousUserBodySync() async throws {
        try await testLogin()
        let user = try await User.current()
        guard let updatedAt = user.updatedAt else {
            XCTFail("Shold have unwrapped")
            return
        }
        XCTAssertTrue(ParseAnonymous<User>.isLinked(with: user))

        var response = UpdateSessionTokenResponse(updatedAt: updatedAt.addingTimeInterval(+300),
            sessionToken: "blast")

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(response)
            // Get dates in correct format from ParseDecoding strategy
            response = try ParseCoding.jsonDecoder().decode(UpdateSessionTokenResponse.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.removeAll()
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let signedInUser = try await User.signup(username: "hello",
                                                 password: "world")
        let currentUser = try await User.current()
        XCTAssertEqual(signedInUser, currentUser)
        XCTAssertEqual(signedInUser.username, "hello")
        XCTAssertEqual(signedInUser.password, "world")
        XCTAssertFalse(ParseAnonymous<User>.isLinked(with: signedInUser))
    }

    func testCantReplaceAnonymousWithDifferentUser() async throws {
        try await testLogin()
        let user = try await User.current()
        XCTAssertTrue(ParseAnonymous<User>.isLinked(with: user))

        let expectation1 = XCTestExpectation(description: "SignUp")
        var differentUser = User()
        differentUser.objectId = "nope"
        differentUser.username = "shouldnot"
        differentUser.password = "work"
        differentUser.signup { result in
            if case let .failure(error) = result {
                XCTAssertEqual(error.code, .otherCause)
                XCTAssertTrue(error.message.contains("different"))
            } else {
                XCTFail("Should have returned error")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testCantReplaceAnonymousWithDifferentUserSync() async throws {
        try await testLogin()
        let user = try await User.current()
        XCTAssertTrue(ParseAnonymous<User>.isLinked(with: user))

        var differentUser = User()
        differentUser.objectId = "nope"
        differentUser.username = "shouldnot"
        differentUser.password = "work"
        do {
            _ = try await differentUser.signup()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.containedIn([.otherCause]))
        }
    }

    func testReplaceAnonymousWithBecome() async throws { // swiftlint:disable:this function_body_length
        try await testLogin()
        MockURLProtocol.removeAll()
        let currentUser = try await User.current()
        XCTAssertNotNil(currentUser.objectId)
        let isLinked = await User.anonymous.isLinked()
        XCTAssertTrue(isLinked)

        let user = try await User.current()
        var serverResponse = LoginSignupResponse()
        serverResponse.createdAt = currentUser.createdAt
        serverResponse.updatedAt = currentUser.updatedAt?.addingTimeInterval(+300)
        serverResponse.sessionToken = "newValue"
        serverResponse.username = "stop"
        serverResponse.password = "this"

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

        let expectation1 = XCTestExpectation(description: "Fetch user1")
        user.become(sessionToken: "newValue") { result in

            switch result {
            case .success(let become):
                XCTAssert(become.hasSameObjectId(as: userOnServer))
                guard let becomeCreatedAt = become.createdAt,
                    let becomeUpdatedAt = become.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt = user.createdAt,
                    let originalUpdatedAt = user.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(becomeCreatedAt, originalCreatedAt)
                XCTAssertGreaterThan(becomeUpdatedAt, originalUpdatedAt)
                XCTAssertNil(become.ACL)

                // Should be updated in memory
                XCTAssertEqual(userOnServer?.updatedAt, becomeUpdatedAt)
                XCTAssertFalse(ParseAnonymous<User>.isLinked(with: become))

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLink() throws {

        let expectation1 = XCTestExpectation(description: "Fetch user1")
        User.anonymous.link(authData: .init()) { result in
            if case let .failure(error) = result {
                XCTAssertEqual(error.message, "Not supported")
            } else {
                XCTFail("Should have returned error")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }
}
