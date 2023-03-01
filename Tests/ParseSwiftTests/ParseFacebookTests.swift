//
//  ParseFacebookTests.swift
//  ParseSwift
//
//  Created by Abdulaziz Alhomaidhi on 3/18/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

// swiftlint:disable type_body_length function_body_length

class ParseFacebookTests: XCTestCase {
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

    func testAuthenticationKeysLimitedLogin() throws {
        let authData = ParseFacebook<User>
            .AuthenticationKeys.id.makeDictionary(userId: "testing",
                                                  accessToken: nil,
                                                  authenticationToken: "authenticationToken")
        XCTAssertEqual(authData, ["id": "testing",
                                  "token": "authenticationToken"])
    }

    func testAuthenticationKeysLimitedLoginExpires() throws {
        let expiresIn = 10
        let authData = ParseFacebook<User>
            .AuthenticationKeys.id.makeDictionary(userId: "testing",
                                                  accessToken: nil,
                                                  authenticationToken: "authenticationToken",
                                                  expiresIn: expiresIn)
        guard let dateString = authData["expiration_date"] else {
            XCTFail("Should have found date")
            return
        }
        XCTAssertEqual(authData, ["id": "testing",
                                  "token": "authenticationToken",
                                  "expiration_date": dateString])
    }

    func testVerifyMandatoryKeys() throws {
        let authData = ["id": "testing",
                        "token": "authenticationToken"]
        XCTAssertTrue(ParseFacebook<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authData))
        let authData2 = ["id": "testing",
                        "access_token": "accessToken"]
        XCTAssertTrue(ParseFacebook<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authData2))
        XCTAssertTrue(ParseFacebook<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authData))
        let authDataWrong = ["id": "testing", "hello": "test"]
        XCTAssertFalse(ParseFacebook<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authDataWrong))
        let authDataWrong2 = ["world": "testing", "token": "test"]
        XCTAssertFalse(ParseFacebook<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authDataWrong2))
        let authDataWrong3 = ["world": "testing", "access_token": "test"]
        XCTAssertFalse(ParseFacebook<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authDataWrong3))
    }

    func testAuthenticationKeysGraphAPILogin() throws {
        let authData = ParseFacebook<User>
            .AuthenticationKeys.id.makeDictionary(userId: "testing",
                                                  accessToken: "accessToken",
                                                  authenticationToken: nil)
        XCTAssertEqual(authData, ["id": "testing", "access_token": "accessToken"])
    }

    func testAuthenticationKeysGraphAPILoginExpires() throws {
        let expiresIn = 10
        let authData = ParseFacebook<User>
            .AuthenticationKeys.id.makeDictionary(userId: "testing",
                                                  accessToken: "accessToken",
                                                  authenticationToken: nil,
                                                  expiresIn: expiresIn)
        guard let dateString = authData["expiration_date"] else {
            XCTFail("Should have found date")
            return
        }
        XCTAssertEqual(authData, ["id": "testing", "access_token": "accessToken", "expiration_date": dateString])
    }

    func testLimitedLogin() throws {
        var serverResponse = LoginSignupResponse()
        let authData = ParseFacebook<User>
            .AuthenticationKeys.id.makeDictionary(userId: "testing",
                                                  accessToken: nil,
                                                  authenticationToken: "authenticationToken")
        serverResponse.username = "hello"
        serverResponse.password = "world"
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

        let expectation1 = XCTestExpectation(description: "Login")

        User.facebook.login(userId: "testing",
                            authenticationToken: "authenticationToken") { result in
            switch result {

            case .success(let user):

                XCTAssertEqual(user, userOnServer)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")

                Task {
                    do {
                        let currentUser = try await User.current()
                        XCTAssertEqual(user, currentUser)
                        var isLinked = await user.facebook.isLinked()
                        XCTAssertTrue(isLinked)

                        // Test stripping
                        let strippedUser = try await user.facebook.strip()
                        isLinked = ParseFacebook.isLinked(with: strippedUser)
                        XCTAssertFalse(isLinked)
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

    func testGraphAPILogin() throws {
        var serverResponse = LoginSignupResponse()
        let authData = ParseFacebook<User>
            .AuthenticationKeys.id.makeDictionary(userId: "testing",
                                                  accessToken: "accessToken",
                                                  authenticationToken: nil)
        serverResponse.username = "hello"
        serverResponse.password = "world"
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

        let expectation1 = XCTestExpectation(description: "Login")

        User.facebook.login(userId: "testing",
                            accessToken: "accessToken") { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user, userOnServer)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                Task {
                    do {
                        let currentUser = try await User.current()
                        XCTAssertEqual(user, currentUser)
                        var isLinked = await user.facebook.isLinked()
                        XCTAssertTrue(isLinked)

                        // Test stripping
                        let strippedUser = try await user.facebook.strip()
                        isLinked = ParseFacebook.isLinked(with: strippedUser)
                        XCTAssertFalse(isLinked)
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
        let authData = ParseFacebook<User>
            .AuthenticationKeys.id.makeDictionary(userId: "testing",
                                                  accessToken: nil,
                                                  authenticationToken: "authenticationToken")
        serverResponse.username = "hello"
        serverResponse.password = "world"
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

        let expectation1 = XCTestExpectation(description: "Login")

        User.facebook.login(authData: authData) { result in
            switch result {

            case .success(let user):
                XCTAssertEqual(user, userOnServer)
                XCTAssertEqual(user.username, "hello")
                XCTAssertEqual(user.password, "world")
                Task {
                    do {
                        let currentUser = try await User.current()
                        XCTAssertEqual(user, currentUser)
                        var isLinked = await user.facebook.isLinked()
                        XCTAssertTrue(isLinked)

                        // Test stripping
                        let strippedUser = try await user.facebook.strip()
                        isLinked = ParseFacebook.isLinked(with: strippedUser)
                        XCTAssertFalse(isLinked)
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
        let currentDate = ParseCoding.dateFormatter.string(from: Date())
        let authData = ["id": "hello",
                        "expirationDate": currentDate]
        User.facebook.login(authData: authData) { result in

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

    func testReplaceAnonymousWithFacebookLimitedLogin() async throws {
        try await loginAnonymousUser()
        MockURLProtocol.removeAll()

        let authData = ParseFacebook<User>
            .AuthenticationKeys.id.makeDictionary(userId: "testing",
                                                  accessToken: nil,
                                                  authenticationToken: "authenticationToken")

        var serverResponse = LoginSignupResponse()
        serverResponse.username = "hello"
        serverResponse.password = "world"
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

        let expectation1 = XCTestExpectation(description: "Login")

        User.facebook.login(userId: "testing",
                            authenticationToken: "authenticationToken") { result in
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
                        let isLinkedUser = await user.facebook.isLinked()
                        XCTAssertTrue(isLinkedUser)
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

    func testReplaceAnonymousWithFacebookGraphAPILogin() async throws {
        try await loginAnonymousUser()
        MockURLProtocol.removeAll()

        let authData = ParseFacebook<User>
            .AuthenticationKeys.id.makeDictionary(userId: "testing",
                                                  accessToken: "this",
                                                  authenticationToken: nil)

        var serverResponse = LoginSignupResponse()
        serverResponse.username = "hello"
        serverResponse.password = "world"
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

        let expectation1 = XCTestExpectation(description: "Login")

        User.facebook.login(userId: "testing",
                            accessToken: "accessToken") { result in
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
                        let isLinkedUser = await user.facebook.isLinked()
                        XCTAssertTrue(isLinkedUser)
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

    func testReplaceAnonymousWithLinkedFacebookLimitedLogin() async throws {
        try await loginAnonymousUser()
        MockURLProtocol.removeAll()
        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()
        let expiresIn = 10
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

        User.facebook.link(userId: "testing", authenticationToken: "authenticationToken",
                           expiresIn: expiresIn) { result in
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
                        let isLinkedUser = await user.facebook.isLinked()
                        XCTAssertTrue(isLinkedUser)
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

    func testReplaceAnonymousWithLinkedFacebookGraphAPILogin() async throws {
        try await loginAnonymousUser()
        MockURLProtocol.removeAll()
        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()
        let expiresIn = 10
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

        User.facebook.link(userId: "testing", accessToken: "acceeToken", expiresIn: expiresIn) { result in
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
                        let isLinkedUser = await user.facebook.isLinked()
                        XCTAssertTrue(isLinkedUser)
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

    func testLinkLoggedInUserWithFacebookLimitedLogin() async throws {
        _ = try await loginNormally()
        MockURLProtocol.removeAll()
        let expiresIn = 10
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

        User.facebook.link(userId: "testing", authenticationToken: "authenticationToken",
                           expiresIn: expiresIn) { result in
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
                        let isLinkedUser = await user.facebook.isLinked()
                        XCTAssertTrue(isLinkedUser)
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

    func testLinkLoggedInUserWithFacebookGraphAPILogin() async throws {
        _ = try await loginNormally()
        MockURLProtocol.removeAll()
        let expiresIn = 10
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

        User.facebook.link(userId: "testing", accessToken: "accessToken", expiresIn: expiresIn) { result in
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
                        let isLinkedUser = await user.facebook.isLinked()
                        XCTAssertTrue(isLinkedUser)
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

        let authData = ParseFacebook<User>
            .AuthenticationKeys.id.makeDictionary(userId: "testing",
                                                  accessToken: nil,
                                                  authenticationToken: "authenticationToken")

        User.facebook.link(authData: authData) { result in
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
                        let isLinkedUser = await user.facebook.isLinked()
                        XCTAssertTrue(isLinkedUser)
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

    func testLinkWrongKeys() async throws {
        _ = try await loginNormally()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Login")
        let currentDate = ParseCoding.dateFormatter.string(from: Date())
        let authData = ["id": "hello",
                        "expirationDate": currentDate]
        User.facebook.link(authData: authData) { result in

            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("consisting of keys"))
            } else {
                XCTFail("Should have returned error")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testUnlinkLimitedLogin() async throws {
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

        let expectation1 = XCTestExpectation(description: "Login")

        User.facebook.unlink { result in
            switch result {

            case .success(let user):
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
                    expectation1.fulfill()
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
                expectation1.fulfill()
            }
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testUnlinkGraphAPILogin() async throws {
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

        let expectation1 = XCTestExpectation(description: "Login")

        User.facebook.unlink { result in
            switch result {

            case .success(let user):
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
                    expectation1.fulfill()
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
                expectation1.fulfill()
            }
        }
        wait(for: [expectation1], timeout: 20.0)
    }
}
