//
//  ParseFacebookTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/28/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

class ParseFacebookTests: XCTestCase { // swiftlint:disable:this type_body_length
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

    @MainActor
    func loginAnonymousUser() async throws {
        let authData = ["id": "yolo"]

        //: Convert the anonymous user to a real new user.
        var serverResponse = LoginSignupResponse()
        serverResponse.username = "hello"
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
        XCTAssertNil(user.password)
        XCTAssertTrue(ParseAnonymous<User>.isLinked(with: user))
    }

    func testAuthenticationKeysLimitedLogin() async throws {
        let authData = ParseFacebook<User>
            .AuthenticationKeys.id.makeDictionary(userId: "testing",
                                                  accessToken: nil,
                                                  authenticationToken: "authenticationToken")
        XCTAssertEqual(authData, ["id": "testing",
                                  "token": "authenticationToken"])
    }

    func testAuthenticationKeysLimitedLoginExpires() async throws {
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

    func testVerifyMandatoryKeys() async throws {
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

    func testAuthenticationKeysGraphAPILogin() async throws {
        let authData = ParseFacebook<User>
            .AuthenticationKeys.id.makeDictionary(userId: "testing",
                                                  accessToken: "accessToken",
                                                  authenticationToken: nil)
        XCTAssertEqual(authData, ["id": "testing", "access_token": "accessToken"])
    }

    func testAuthenticationKeysGraphAPILoginExpires() async throws {
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

    @MainActor
    func testLimitedLogin() async throws {
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

        let user = try await User.facebook.login(userId: "testing",
                                                 authenticationToken: "authenticationToken")

        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        XCTAssertEqual(user, userOnServer)
        let isLinked = await user.facebook.isLinked()
        XCTAssertTrue(isLinked)
        XCTAssertEqual(user.username, "hello")
        XCTAssertNil(user.password)
    }

    @MainActor
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

        let authData = ParseFacebook<User>
            .AuthenticationKeys.id.makeDictionary(userId: "testing",
                                                  accessToken: nil,
                                                  authenticationToken: "authenticationToken")

        let user = try await User.facebook.link(authData: authData)
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        var isLinked = await user.facebook.isLinked()
        XCTAssertTrue(isLinked)
        isLinked = await user.anonymous.isLinked()
        XCTAssertFalse(isLinked)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
    }

    @MainActor
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

        let encoded: Data!
        do {
            encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let user = try await User.facebook.login(userId: "testing",
                                                 authenticationToken: "authenticationToken")
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        let isLinked = await user.facebook.isLinked()
        XCTAssertTrue(isLinked)
        XCTAssertEqual(user.username, "hello")
        XCTAssertNil(user.password)
    }

    @MainActor
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

        let user = try await User.facebook.link(userId: "testing",
                                                authenticationToken: "authenticationToken",
                                                expiresIn: expiresIn)
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        var isLinked = await user.facebook.isLinked()
        XCTAssertTrue(isLinked)
        isLinked = await user.anonymous.isLinked()
        XCTAssertFalse(isLinked)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
    }

    @MainActor
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

        let user = try await User.facebook.link(userId: "testing",
                                                authenticationToken: "authenticationToken",
                                                expiresIn: expiresIn)
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        var isLinked = await user.facebook.isLinked()
        XCTAssertTrue(isLinked)
        isLinked = await user.anonymous.isLinked()
        XCTAssertFalse(isLinked)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello")
        XCTAssertNil(user.password)
    }

    @MainActor
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

        let user = try await User.facebook.link(userId: "testing",
                                                accessToken: "accessToken",
                                                expiresIn: expiresIn)
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        var isLinked = await user.facebook.isLinked()
        XCTAssertTrue(isLinked)
        isLinked = await user.anonymous.isLinked()
        XCTAssertFalse(isLinked)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello")
        XCTAssertNil(user.password)
    }

    @MainActor
    func testGraphAPILogin() async throws {
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

        let user = try await User.facebook.login(userId: "testing", accessToken: "accessToken")
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        XCTAssertEqual(user, userOnServer)
        let isLinked = await user.facebook.isLinked()
        XCTAssertTrue(isLinked)
        XCTAssertEqual(user.username, "hello")
        XCTAssertNil(user.password)
    }

    @MainActor
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

        let user = try await User.facebook.login(userId: "testing",
                                                 accessToken: "accessToken")

        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        let isLinked = await user.facebook.isLinked()
        XCTAssertTrue(isLinked)
        XCTAssertEqual(user.username, "hello")
        XCTAssertNil(user.password)
    }

    @MainActor
    func testLoginAuthData() async throws {

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

        let user = try await User.facebook.login(authData: faceookAuthData)
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        XCTAssertEqual(user, userOnServer)
        var isLinked = await user.facebook.isLinked()
        XCTAssertTrue(isLinked)
        XCTAssertEqual(user.username, "hello")
        XCTAssertNil(user.password)

        // Test stripping
        let strippedUser = user.facebook.strip(currentUser)
        isLinked = ParseFacebook.isLinked(with: strippedUser)
        XCTAssertFalse(isLinked)
    }

    @MainActor
    func testLinkLimitedLogin() async throws {

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

        let user = try await User.facebook.link(userId: "testing",
                                                authenticationToken: "authenticationToken")
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        var isLinked = await user.facebook.isLinked()
        XCTAssertTrue(isLinked)
        isLinked = await user.anonymous.isLinked()
        XCTAssertFalse(isLinked)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
    }

    @MainActor
    func testLinkGraphAPILogin() async throws {

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

        let user = try await User.facebook.link(userId: "testing",
                                                accessToken: "accessToken")
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        var isLinked = await user.facebook.isLinked()
        XCTAssertTrue(isLinked)
        isLinked = await user.anonymous.isLinked()
        XCTAssertFalse(isLinked)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
    }

    @MainActor
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

        let user = try await User.facebook.link(userId: "testing",
                                                accessToken: "accessToken",
                                                expiresIn: expiresIn)
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        var isLinked = await user.facebook.isLinked()
        XCTAssertTrue(isLinked)
        isLinked = await user.anonymous.isLinked()
        XCTAssertFalse(isLinked)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
    }

    @MainActor
    func testLinkAuthData() async throws {

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

        let user = try await User.facebook.link(authData: authData)
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        var isLinked = await user.facebook.isLinked()
        XCTAssertTrue(isLinked)
        isLinked = await user.anonymous.isLinked()
        XCTAssertFalse(isLinked)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
    }

    @MainActor
    func testUnlinkLimitedLogin() async throws {

        _ = try await loginNormally()
        MockURLProtocol.removeAll()

        let authData = ParseFacebook<User>
            .AuthenticationKeys.id.makeDictionary(userId: "testing",
                                                  accessToken: nil,
                                                  authenticationToken: "authenticationToken")
        var userAuth = try await User.current()
        userAuth.authData = [User.facebook.__type: authData]
        try await User.setCurrent(userAuth)
        let isLinkedAuth = await User.facebook.isLinked()
        XCTAssertTrue(isLinkedAuth)

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

        let user = try await User.facebook.unlink()
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        let isLinked = await user.facebook.isLinked()
        XCTAssertFalse(isLinked)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
    }

    @MainActor
    func testUnlinkGraphAPILogin() async throws {

        _ = try await loginNormally()
        MockURLProtocol.removeAll()

        let authData = ParseFacebook<User>
            .AuthenticationKeys.id.makeDictionary(userId: "testing",
                                                  accessToken: "accessToken",
                                                  authenticationToken: nil)
        var userAuth = try await User.current()
        userAuth.authData = [User.facebook.__type: authData]
        try await User.setCurrent(userAuth)
        let isLinkedAuth = await User.facebook.isLinked()
        XCTAssertTrue(isLinkedAuth)

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

        let user = try await User.facebook.unlink()
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        let isLinked = await user.facebook.isLinked()
        XCTAssertFalse(isLinked)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
    }

    @MainActor
    func testLoginWrongKeys() async throws {
        _ = try await loginNormally()
        MockURLProtocol.removeAll()

        let currentDate = ParseCoding.dateFormatter.string(from: Date())
        let authData = ["id": "hello",
                        "expirationDate": currentDate]
        do {
            _ = try await User.facebook.login(authData: authData)
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted to ParseError")
                return
            }
            XCTAssertTrue(parseError.message.contains("consisting of keys"))
        }
    }

    @MainActor
    func testLinkWrongKeys() async throws {
        _ = try await loginNormally()
        MockURLProtocol.removeAll()

        let currentDate = ParseCoding.dateFormatter.string(from: Date())
        let authData = ["id": "hello",
                        "expirationDate": currentDate]
        do {
            _ = try await User.facebook.link(authData: authData)
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted to ParseError")
                return
            }
            XCTAssertTrue(parseError.message.contains("consisting of keys"))
        }
    }
}
