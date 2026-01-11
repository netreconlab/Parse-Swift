//
//  ParseSpotifyTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 06/21/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

// Currently can't takeover URLSession with MockURLProtocol
// on Linux, Windows, etc. so disabling networking tests on
// those platforms.
#if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

// swiftlint:disable type_body_length

class ParseSpotifyTests: XCTestCase, @unchecked Sendable {
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
        #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        try KeychainStore.shared.deleteAll()
        #endif
        try await ParseStorage.shared.deleteAll()
    }

    @MainActor
    func loginNormally() async throws -> User {
        let loginResponse = LoginSignupResponse()

        let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
        MockURLProtocol.mockRequests { _ in
			MockURLResponse(data: encoded, statusCode: 200)
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
        let current = try await User.current()
        XCTAssertEqual(user, current)
        XCTAssertEqual(user, userOnServer)
        XCTAssertEqual(user.username, "hello")
        XCTAssertNil(user.password)
        XCTAssertTrue(ParseAnonymous<User>.isLinked(with: user))
    }

    @MainActor
    func testAuthenticationKeys() async throws {
        let authData = ParseSpotify<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "access_token")
        XCTAssertEqual(authData, ["id": "testing", "access_token": "access_token"])
    }

    @MainActor
    func testAuthenticationWithOptinalKeys() async throws {
        let authData = ParseSpotify<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "access_token",
                                                  expiresIn: 10,
                                                  refreshToken: "refresh_token")
        guard let dateString = authData["expiration_date"] else {
            XCTFail("Should have found date")
            return
        }
        XCTAssertEqual(authData, ["id": "testing",
                                  "access_token": "access_token",
                                  "expiration_date": dateString,
                                  "refresh_token": "refresh_token"])
    }

    @MainActor
    func testVerifyMandatoryKeys() async throws {
        let authData = ["id": "testing", "access_token": "access_token"]
        let authDataWrong = ["id": "testing", "hello": "test"]
        XCTAssertTrue(ParseSpotify<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authData))
        XCTAssertFalse(ParseSpotify<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authDataWrong))
    }

    @MainActor
    func testLogin() async throws {
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

        let user = try await User.spotify.login(id: "testing", accessToken: "access_token")
        let current = try await User.current()
        XCTAssertEqual(user, current)
        var isLinked = ParseSpotify.isLinked(with: current)
        XCTAssertTrue(isLinked)
        XCTAssertEqual(user.authData, userOnServer.authData)
        XCTAssertEqual(user.username, "hello")
        XCTAssertNil(user.password)
        XCTAssertFalse(ParseAnonymous<User>.isLinked(with: user))

        // Test stripping
        let strippedUser = user.spotify.strip(current)
        isLinked = ParseSpotify.isLinked(with: strippedUser)
        XCTAssertFalse(isLinked)
    }

    @MainActor
    func testLoginAuthData() async throws {
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

        let user = try await User.spotify.login(authData: ["id": "testing",
                                                         "access_token": "access_token"])
        let current = try await User.current()
        XCTAssertEqual(user, current)
        let isLinked = ParseSpotify.isLinked(with: current)
        XCTAssertTrue(isLinked)
        XCTAssertEqual(user.authData, userOnServer.authData)
        XCTAssertEqual(user.username, "hello")
        XCTAssertNil(user.password)
        XCTAssertFalse(ParseAnonymous<User>.isLinked(with: user))
    }

    @MainActor
    func testReplaceAnonymousWithSpotify() async throws {
        try await loginAnonymousUser()
        MockURLProtocol.removeAll()

        let authData = ParseSpotify<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "access_token")

        var serverResponse = LoginSignupResponse()
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.spotify.__type: authData,
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

        let user = try await User.spotify.login(id: "testing", accessToken: "access_token")
        let current = try await User.current()
        XCTAssertEqual(user, current)
        let isLinked = ParseSpotify.isLinked(with: current)
        XCTAssertTrue(isLinked)
        XCTAssertEqual(user.authData, userOnServer.authData)
        XCTAssertEqual(user.username, "hello")
        XCTAssertNil(user.password)
        XCTAssertFalse(ParseAnonymous<User>.isLinked(with: user))
    }

    @MainActor
    func testReplaceAnonymousWithLinkedSpotify() async throws {
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

        let user = try await User.spotify.link(id: "testing", accessToken: "access_token")
        let current = try await User.current()
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user, current)
        let isLinked = ParseSpotify.isLinked(with: current)
        XCTAssertTrue(isLinked)
        XCTAssertEqual(user.username, "hello")
        XCTAssertNil(user.password)
        XCTAssertFalse(ParseAnonymous<User>.isLinked(with: user))
    }

    @MainActor
    func testLinkLoggedInUserWithSpotify() async throws {
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

        let user = try await User.spotify.link(id: "testing", accessToken: "access_token")
        let current = try await User.current()
        XCTAssertEqual(user, current)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        let isLinked = ParseSpotify.isLinked(with: current)
        XCTAssertTrue(isLinked)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
        XCTAssertFalse(ParseAnonymous<User>.isLinked(with: user))
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

        let authData = ParseSpotify<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "access_token")

        let user = try await User.spotify.link(authData: authData)
        let current = try await User.current()
        XCTAssertEqual(user, current)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        let isLinked = ParseSpotify.isLinked(with: current)
        XCTAssertTrue(isLinked)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
        XCTAssertFalse(ParseAnonymous<User>.isLinked(with: user))
    }

    @MainActor
    func testLoginWrongKeys() async throws {
        _ = try await loginNormally()
        MockURLProtocol.removeAll()

        do {
            _ = try await User.spotify.login(authData: ["hello": "world"])
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
    func testLinkLoggedInUserWrongKeys() async throws {
        _ = try await loginNormally()
        MockURLProtocol.removeAll()

        do {
            _ = try await User.spotify.link(authData: ["hello": "world"])
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
    func testLink() async throws {
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

        let user = try await User.spotify.link(id: "testing", accessToken: "access_token")
        let current = try await User.current()
        XCTAssertEqual(user, current)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        let isLinked = ParseSpotify.isLinked(with: current)
        XCTAssertTrue(isLinked)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
        XCTAssertFalse(ParseAnonymous<User>.isLinked(with: user))
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

        let user = try await User.spotify.link(authData: ["id": "testing",
                                                          "access_token": "access_token"])
        let current = try await User.current()
        XCTAssertEqual(user, current)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        let isLinked = ParseSpotify.isLinked(with: current)
        XCTAssertTrue(isLinked)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
        XCTAssertFalse(ParseAnonymous<User>.isLinked(with: user))
    }

    @MainActor
    func testUnlink() async throws {
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

        user = try await User.spotify.unlink()
        let current = try await User.current()
        XCTAssertEqual(user, current)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        let isLinked = ParseSpotify.isLinked(with: current)
        XCTAssertFalse(isLinked)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
    }
}
#endif
