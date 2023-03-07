//
//  ParseUserTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 7/21/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

// swiftlint:disable function_body_length

class ParseUserTests: XCTestCase { // swiftlint:disable:this type_body_length

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

        //: Implement your own version of merge
        func merge(with object: Self) throws -> Self {
            var updated = try mergeParse(with: object)
            if updated.shouldRestoreKey(\.customKey,
                                         original: object) {
                updated.customKey = object.customKey
            }
            return updated
        }
    }

    struct UserDefaultMerge: ParseUser {

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

    struct UserDefault: ParseUser {

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

        func createUser() -> User {
            var user = User()
            user.objectId = objectId
            user.ACL = ACL
            user.customKey = customKey
            user.username = username
            user.email = email
            return user
        }
    }

    let loginUserName = "hello10"
    let loginPassword = "world"

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
    func userSignUp() async throws {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        _ = try await loginResponse.createUser().signup()
        MockURLProtocol.removeAll()
        let currentUser = try await User.current()
        XCTAssertEqual(currentUser.objectId, loginResponse.objectId)
        XCTAssertEqual(currentUser.username, loginResponse.username)
        XCTAssertEqual(currentUser.email, loginResponse.email)
        XCTAssertEqual(currentUser.ACL, loginResponse.ACL)
        XCTAssertEqual(currentUser.customKey, loginResponse.customKey)
    }

    func testMerge() async throws {
        // Signup current User
        try await userSignUp()
        var original = try await User.current()
        XCTAssertNotNil(original.objectId)

        original.objectId = "yolo"
        original.createdAt = Date()
        original.updatedAt = Date()
        original.authData = ["hello": ["world": "yolo"]]
        var acl = ParseACL()
        acl.publicRead = true
        original.ACL = acl

        var updated = original.mergeable
        updated.updatedAt = Calendar.current.date(byAdding: .init(day: 1), to: Date())
        updated.email = "swift@parse.com"
        updated.username = "12345"
        updated.customKey = "newKey"
        let merged = try updated.merge(with: original)
        XCTAssertEqual(merged.customKey, updated.customKey)
        XCTAssertEqual(merged.email, updated.email)
        XCTAssertEqual(merged.emailVerified, original.emailVerified)
        XCTAssertEqual(merged.username, updated.username)
        XCTAssertEqual(merged.authData, original.authData)
        XCTAssertEqual(merged.ACL, original.ACL)
        XCTAssertEqual(merged.createdAt, original.createdAt)
        XCTAssertEqual(merged.updatedAt, updated.updatedAt)
    }

    func testMerge2() async throws {
        // Signup current User
        try await userSignUp()
        var original = try await User.current()
        XCTAssertNotNil(original.objectId)

        original.objectId = "yolo"
        original.createdAt = Date()
        original.updatedAt = Date()
        var acl = ParseACL()
        acl.publicRead = true
        original.ACL = acl

        var updated = original.mergeable
        updated.updatedAt = Calendar.current.date(byAdding: .init(day: 1), to: Date())
        updated.customKey = "newKey"
        let merged = try updated.merge(with: original)
        XCTAssertEqual(merged.customKey, updated.customKey)
        XCTAssertEqual(merged.email, original.email)
        XCTAssertEqual(merged.emailVerified, original.emailVerified)
        XCTAssertEqual(merged.username, original.username)
        XCTAssertEqual(merged.authData, original.authData)
        XCTAssertEqual(merged.ACL, original.ACL)
        XCTAssertEqual(merged.createdAt, original.createdAt)
        XCTAssertEqual(merged.updatedAt, updated.updatedAt)
    }

    func testMergeDefaultImplementation() async throws {
        // Signup current User
        try await userSignUp()
        let currentUser = try await User.current()
        XCTAssertNotNil(currentUser.objectId)

        var original = UserDefaultMerge()
        original.username = currentUser.username
        original.email = currentUser.email
        original.customKey = currentUser.customKey
        original.objectId = "yolo"
        original.createdAt = Date()
        original.updatedAt = Date()
        var acl = ParseACL()
        acl.publicRead = true
        original.ACL = acl

        var updated = original.set(\.customKey, to: "newKey")
        updated.updatedAt = Calendar.current.date(byAdding: .init(day: 1), to: Date())
        original.customKey = updated.customKey
        original.updatedAt = updated.updatedAt
        var merged = try updated.merge(with: original)
        merged.originalData = nil
        // Get dates in correct format from ParseDecoding strategy
        let encoded = try ParseCoding.jsonEncoder().encode(original)
        original = try ParseCoding.jsonDecoder().decode(UserDefaultMerge.self, from: encoded)
        XCTAssertEqual(merged, original)
    }

    func testMergeDifferentObjectId() throws {
        var user = User()
        user.objectId = "yolo"
        var user2 = user
        user2.objectId = "nolo"
        XCTAssertThrowsError(try user2.merge(with: user))
    }

    func testOriginalDataNeverSavesToKeychain() async throws {
        // Signup current User
        try await login()
        MockURLProtocol.removeAll()
        let original = try await User.current()
        XCTAssertNotNil(original.objectId)

        var mutated = original
        mutated.originalData = Data()
        try await User.setCurrent(mutated)
        let saved = try await User.current()
        XCTAssertTrue(saved.hasSameObjectId(as: original))
        XCTAssertNil(original.originalData)
        XCTAssertNil(saved.originalData)
        XCTAssertEqual(saved.customKey, original.customKey)
        XCTAssertEqual(saved.email, original.email)
        XCTAssertEqual(saved.username, original.username)
        XCTAssertEqual(saved.emailVerified, original.emailVerified)
        XCTAssertEqual(saved.password, original.password)
        XCTAssertEqual(saved.authData, original.authData)
        XCTAssertEqual(saved.createdAt, original.createdAt)
        XCTAssertEqual(saved.updatedAt, original.updatedAt)
    }

    @MainActor
    func testSignupCommandWithBody() async throws {
        let body = SignupLoginBody(username: "test", password: "user")
        let command = try User.signupCommand(body: body)
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertEqual(command.body?.username, body.username)
        XCTAssertEqual(command.body?.password, body.password)
    }

    @MainActor
    func testSignupCommandNoBody() async throws {
        var user = User()
        user.username = "test"
        user.password = "user"
        user.customKey = "hello"
        let command = try user.signupCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertEqual(command.body?.username, "test")
        XCTAssertEqual(command.body?.password, "user")
        XCTAssertEqual(command.body?.customKey, "hello")
    }

    @MainActor
    func testSignup() async throws {
        let loginResponse = LoginSignupResponse()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let signedUp = try await User.signup(username: loginUserName, password: loginUserName)
        XCTAssertNotNil(signedUp)
        XCTAssertNotNil(signedUp.createdAt)
        XCTAssertNotNil(signedUp.updatedAt)
        XCTAssertNotNil(signedUp.email)
        XCTAssertNotNil(signedUp.username)
        XCTAssertNil(signedUp.password)
        XCTAssertNotNil(signedUp.objectId)
        XCTAssertNotNil(signedUp.customKey)
        XCTAssertNil(signedUp.ACL)

        let userFromKeychain = try await BaseParseUser.current()
        XCTAssertNotNil(userFromKeychain.createdAt)
        XCTAssertNotNil(userFromKeychain.updatedAt)
        XCTAssertNotNil(userFromKeychain.email)
        XCTAssertNotNil(userFromKeychain.username)
        XCTAssertNil(userFromKeychain.password)
        XCTAssertNotNil(userFromKeychain.objectId)
        _ = try await BaseParseUser.sessionToken()
        XCTAssertNil(userFromKeychain.ACL)
    }

    @MainActor
    func testSignUpNoBody() async throws {
        var loginResponse = LoginSignupResponse()
        loginResponse.email = nil

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        var user = User()
        user.username = loginUserName
        user.password = loginPassword
        user.customKey = "blah"
        let signedUp = try await user.signup()
        XCTAssertNotNil(signedUp)
        XCTAssertNotNil(signedUp.createdAt)
        XCTAssertNotNil(signedUp.updatedAt)
        XCTAssertNil(signedUp.email)
        XCTAssertNotNil(signedUp.username)
        XCTAssertNil(signedUp.password)
        XCTAssertNotNil(signedUp.objectId)
        let sessionToken = try? await User.sessionToken()
        XCTAssertNotNil(sessionToken)
        XCTAssertNotNil(signedUp.customKey)
        XCTAssertNil(signedUp.ACL)

        let userFromKeychain = try await BaseParseUser.current()

        XCTAssertNotNil(userFromKeychain.createdAt)
        XCTAssertNotNil(userFromKeychain.updatedAt)
        XCTAssertNil(userFromKeychain.email)
        XCTAssertNotNil(userFromKeychain.username)
        XCTAssertNil(userFromKeychain.password)
        XCTAssertNotNil(userFromKeychain.objectId)
        XCTAssertNil(userFromKeychain.ACL)
    }

    @MainActor
    func testSignupInstance() async throws {
        let loginResponse = LoginSignupResponse()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        var user = User()
        user.username = loginUserName
        user.password = loginPassword
        user.email = "parse@parse.com"
        user.customKey = "blah"
        let signedUp = try await user.signup()
        XCTAssertNotNil(signedUp)
        XCTAssertNotNil(signedUp.createdAt)
        XCTAssertNotNil(signedUp.updatedAt)
        XCTAssertNotNil(signedUp.email)
        XCTAssertNotNil(signedUp.username)
        XCTAssertNil(signedUp.password)
        XCTAssertNotNil(signedUp.objectId)
        _ = try await BaseParseUser.sessionToken()
        XCTAssertNotNil(signedUp.customKey)
        XCTAssertNil(signedUp.ACL)

        let userFromKeychain = try await BaseParseUser.current()

        XCTAssertNotNil(userFromKeychain.createdAt)
        XCTAssertNotNil(userFromKeychain.updatedAt)
        XCTAssertNotNil(userFromKeychain.email)
        XCTAssertNotNil(userFromKeychain.username)
        XCTAssertNil(userFromKeychain.password)
        XCTAssertNotNil(userFromKeychain.objectId)
        _ = try await BaseParseUser.sessionToken()
        XCTAssertNil(userFromKeychain.ACL)
    }

    @MainActor
    func testLoginCommand() async throws {
        let command = User.loginCommand(username: "test", password: "user")
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/login")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNotNil(command.body)
    }

    @MainActor
    func testLogin() async throws {
        let loginResponse = LoginSignupResponse()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let signedUp = try await User.login(username: loginUserName, password: loginUserName)
        XCTAssertNotNil(signedUp)
        XCTAssertNotNil(signedUp.createdAt)
        XCTAssertNotNil(signedUp.updatedAt)
        XCTAssertNotNil(signedUp.email)
        XCTAssertNotNil(signedUp.username)
        XCTAssertNil(signedUp.password)
        XCTAssertNotNil(signedUp.objectId)
        XCTAssertNotNil(signedUp.customKey)
        XCTAssertNil(signedUp.ACL)

        let userFromKeychain = try await BaseParseUser.current()

        XCTAssertNotNil(userFromKeychain.createdAt)
        XCTAssertNotNil(userFromKeychain.updatedAt)
        XCTAssertNotNil(userFromKeychain.email)
        XCTAssertNotNil(userFromKeychain.username)
        XCTAssertNil(userFromKeychain.password)
        XCTAssertNotNil(userFromKeychain.objectId)
        _ = try await BaseParseUser.sessionToken()
        XCTAssertNil(userFromKeychain.ACL)
    }

    @MainActor
    func login() async throws {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        _ = try await User.login(username: loginUserName, password: loginPassword)
    }

    @MainActor
    func testMeCommand() async throws {
        var user = User()
        user.objectId = "me"
        let command = try user.meCommand(sessionToken: "yolo")
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users/me")
        XCTAssertEqual(command.method, API.Method.GET)
        XCTAssertNil(command.params)
        XCTAssertNil(command.body)
    }

    @MainActor
    func testBecome() async throws {
        try await login()
        MockURLProtocol.removeAll()

        let user = try await User.current()

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = user.updatedAt?.addingTimeInterval(+300)
        serverResponse.sessionToken = "newValue"
        serverResponse.username = "stop"

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        guard let sessionToken = serverResponse.sessionToken else {
            XCTFail("Should have unwrapped")
            return
        }
        let signedUp = try await user.become(sessionToken: sessionToken)
        XCTAssertNotNil(signedUp)
        XCTAssertNotNil(signedUp.updatedAt)
        XCTAssertNotNil(signedUp.email)
        XCTAssertNotNil(signedUp.username)
        XCTAssertNil(signedUp.password)
        XCTAssertNotNil(signedUp.objectId)
        XCTAssertNotNil(signedUp.customKey)
        XCTAssertNil(signedUp.ACL)

        let userFromKeychain = try await BaseParseUser.current()

        XCTAssertNotNil(userFromKeychain.createdAt)
        XCTAssertNotNil(userFromKeychain.updatedAt)
        XCTAssertNotNil(userFromKeychain.email)
        XCTAssertNotNil(userFromKeychain.username)
        XCTAssertNil(userFromKeychain.password)
        XCTAssertNotNil(userFromKeychain.objectId)
        _ = try await BaseParseUser.sessionToken()
        XCTAssertNil(userFromKeychain.ACL)
    }

    @MainActor
    func testLogutCommand() async throws {
        let command = User.logoutCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/logout")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.body)
    }

    @MainActor
    func testLogout() async throws {
        try await login()
        MockURLProtocol.removeAll()

        let serverResponse = NoBody()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        guard let oldInstallationId = try await BaseParseInstallation.current().installationId else {
            XCTFail("Should have unwrapped")
            return
        }

        _ = try await User.logout()

        do {
            _ = try await BaseParseUser.current()
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted to ParseError")
                return
            }
            XCTAssertTrue(parseError.message.contains("no current"))
        }

        if let installationFromMemory: CurrentInstallationContainer<BaseParseInstallation>
            = try await ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentInstallation) {
            if installationFromMemory.installationId == oldInstallationId
                || installationFromMemory.installationId == nil {
                XCTFail("\(installationFromMemory) was not deleted and recreated in memory during logout")
            }
        } else {
            XCTFail("Should have a new installation")
        }

        #if !os(Linux) && !os(Android) && !os(Windows)
        if let installationFromKeychain: CurrentInstallationContainer<BaseParseInstallation>
            = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) {
            if installationFromKeychain.installationId == oldInstallationId
                || installationFromKeychain.installationId == nil {
                XCTFail("\(installationFromKeychain) was not deleted & recreated in Keychain during logout")
            }
        } else {
            XCTFail("Should have a new installation")
        }
        #endif
    }

    @MainActor
    func testLogoutError() async throws {
        try await login()
        MockURLProtocol.removeAll()

        let serverResponse = ParseError(code: .internalServer, message: "Object not found")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        guard let oldInstallationId = try await BaseParseInstallation.current().installationId else {
            XCTFail("Should have unwrapped")
            return
        }

        do {
            _ = try await User.logout()
            XCTFail("Should have thrown error")
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("Should be ParseError")
                return
            }
            XCTAssertEqual(error.message, serverResponse.message)
        }

        do {
            _ = try await BaseParseUser.current()
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted to ParseError")
                return
            }
            XCTAssertTrue(parseError.message.contains("no current"))
        }

        if let installationFromMemory: CurrentInstallationContainer<BaseParseInstallation>
            = try await ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentInstallation) {
                if installationFromMemory.installationId == oldInstallationId
                    || installationFromMemory.installationId == nil {
                    XCTFail("\(installationFromMemory) was not deleted & recreated in memory during logout")
                }
        } else {
            XCTFail("Should have a new installation")
        }

        #if !os(Linux) && !os(Android) && !os(Windows)
        if let installationFromKeychain: CurrentInstallationContainer<BaseParseInstallation>
            = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) {
                if installationFromKeychain.installationId == oldInstallationId
                    || installationFromKeychain.installationId == nil {
                    XCTFail("\(installationFromKeychain) was not deleted & recreated in Keychain during logout")
                }
        } else {
            XCTFail("Should have a new installation")
        }
        #endif

    }

    @MainActor
    func testPasswordResetCommand() async throws {
        let body = EmailBody(email: "hello@parse.org")
        let command = User.passwordResetCommand(email: body.email)
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/requestPasswordReset")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertEqual(command.body?.email, body.email)
    }

    @MainActor
    func testPasswordReset() async throws {
        let serverResponse = NoBody()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        _ = try await User.passwordReset(email: "hello@parse.org")
    }

    @MainActor
    func testPasswordResetError() async throws {
        let parseError = ParseError(code: .internalServer, message: "Object not found")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(parseError)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        do {
            try await User.passwordReset(email: "hello@parse.org")
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("Should be ParseError")
                return
            }
            XCTAssertEqual(error.code, parseError.code)
        }
    }

    @MainActor
    func testVerifyPasswordCommandPOST() async throws {
        let username = "hello"
        let password = "world"
        let command = User.verifyPasswordCommand(username: username,
                                                 password: password,
                                                 method: .POST)
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/verifyPassword")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertEqual(command.body?.username, username)
        XCTAssertEqual(command.body?.password, password)
        XCTAssertNil(command.params)
    }

    @MainActor
    func testVerifyPasswordCommandGET() async throws {
        let username = "hello"
        let password = "world"
        let params = ["username": username,
                      "password": password]
        let command = User.verifyPasswordCommand(username: username,
                                                 password: password,
                                                 method: .GET)
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/verifyPassword")
        XCTAssertEqual(command.method, API.Method.GET)
        XCTAssertNil(command.body)
        XCTAssertEqual(command.params, params)
    }

    @MainActor
    func testVerificationEmailRequestCommand() async throws {
        let body = EmailBody(email: "hello@parse.org")
        let command = User.verificationEmailCommand(email: body.email)
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/verificationEmailRequest")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertEqual(command.body?.email, body.email)
    }

    @MainActor
    func testVerifyPasswordLoggedIn() async throws {
        try await login()
        MockURLProtocol.removeAll()

        var serverResponse = LoginSignupResponse()
        serverResponse.sessionToken = nil

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let currentUser = try await User.verifyPassword(password: "world", usingPost: true)
        XCTAssertNotNil(currentUser)
        XCTAssertNotNil(currentUser.createdAt)
        XCTAssertNotNil(currentUser.updatedAt)
        XCTAssertNotNil(currentUser.email)
        XCTAssertNotNil(currentUser.username)
        XCTAssertNil(currentUser.password)
        XCTAssertNotNil(currentUser.objectId)
        XCTAssertNotNil(currentUser.customKey)
        XCTAssertNil(currentUser.ACL)

        let userFromKeychain = try await BaseParseUser.current()

        XCTAssertNotNil(userFromKeychain.createdAt)
        XCTAssertNotNil(userFromKeychain.updatedAt)
        XCTAssertNotNil(userFromKeychain.email)
        XCTAssertNotNil(userFromKeychain.username)
        XCTAssertNil(userFromKeychain.password)
        XCTAssertNotNil(userFromKeychain.objectId)
        _ = try await BaseParseUser.sessionToken()
        XCTAssertNil(userFromKeychain.ACL)
    }

    func testVerifyPasswordLoggedInGET() async throws {
        try await login()
        MockURLProtocol.removeAll()

        var serverResponse = LoginSignupResponse()
        serverResponse.sessionToken = nil

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let currentUser = try await User.verifyPassword(password: "world", usingPost: false)
        XCTAssertNotNil(currentUser)
        XCTAssertNotNil(currentUser.createdAt)
        XCTAssertNotNil(currentUser.updatedAt)
        XCTAssertNotNil(currentUser.email)
        XCTAssertNotNil(currentUser.username)
        XCTAssertNil(currentUser.password)
        XCTAssertNotNil(currentUser.objectId)
        XCTAssertNotNil(currentUser.customKey)
        XCTAssertNil(currentUser.ACL)

        let userFromKeychain = try await BaseParseUser.current()

        XCTAssertNotNil(userFromKeychain.createdAt)
        XCTAssertNotNil(userFromKeychain.updatedAt)
        XCTAssertNotNil(userFromKeychain.email)
        XCTAssertNotNil(userFromKeychain.username)
        XCTAssertNil(userFromKeychain.password)
        XCTAssertNotNil(userFromKeychain.objectId)
        _ = try await BaseParseUser.sessionToken()
        XCTAssertNil(userFromKeychain.ACL)
    }

    @MainActor
    func testVerifyPasswordNotLoggedIn() async throws {
        let serverResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let currentUser = try await User.verifyPassword(password: "world")
        XCTAssertNotNil(currentUser)
        XCTAssertNotNil(currentUser.createdAt)
        XCTAssertNotNil(currentUser.updatedAt)
        XCTAssertNotNil(currentUser.email)
        XCTAssertNotNil(currentUser.username)
        XCTAssertNil(currentUser.password)
        XCTAssertNotNil(currentUser.objectId)
        XCTAssertNotNil(currentUser.customKey)
        XCTAssertNil(currentUser.ACL)

        let userFromKeychain = try await BaseParseUser.current()

        XCTAssertNotNil(userFromKeychain.createdAt)
        XCTAssertNotNil(userFromKeychain.updatedAt)
        XCTAssertNotNil(userFromKeychain.email)
        XCTAssertNotNil(userFromKeychain.username)
        XCTAssertNil(userFromKeychain.password)
        XCTAssertNotNil(userFromKeychain.objectId)
        _ = try await BaseParseUser.sessionToken()
        XCTAssertNil(userFromKeychain.ACL)
    }

    @MainActor
    func testVerifyPasswordLoggedInError() async throws {
        try await login()
        MockURLProtocol.removeAll()

        let parseError = ParseError(code: .userWithEmailNotFound,
                                    message: "User email is not verified.")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(parseError)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        do {
            _ = try await User.verifyPassword(password: "blue")
            XCTFail("Should have thrown error")
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("Should be ParseError")
                return
            }
            XCTAssertEqual(error.code, parseError.code)
        }
    }

    @MainActor
    func testVerificationEmail() async throws {
        let serverResponse = NoBody()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        _ = try await User.verificationEmail(email: "hello@parse.org")
    }

    @MainActor
    func testVerificationEmailError() async throws {
        let parseError = ParseError(code: .internalServer, message: "Object not found")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(parseError)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        do {
            _ = try await User.verificationEmail(email: "hello@parse.org")
            XCTFail("Should have thrown error")
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("Should be ParseError")
                return
            }
            XCTAssertEqual(error.code, parseError.code)
        }
    }

    @MainActor
    func testFetchCommand() async throws {
        var user = User()
        XCTAssertThrowsError(try user.fetchCommand(include: nil))
        let objectId = "yarr"
        user.objectId = objectId
        let command = try user.fetchCommand(include: nil)
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users/\(objectId)")
        XCTAssertEqual(command.method, API.Method.GET)
        XCTAssertNil(command.params)
        XCTAssertNil(command.body)

        let user2 = User()
        XCTAssertThrowsError(try user2.fetchCommand(include: nil))
    }

    @MainActor
    func testFetchIncludeCommand() async throws {
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId
        let includeExpected = ["include": "[\"yolo\", \"test\"]"]
        let command = try user.fetchCommand(include: ["yolo", "test"])
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users/\(objectId)")
        XCTAssertEqual(command.method, API.Method.GET)
        XCTAssertEqual(command.params?.keys.first, includeExpected.keys.first)
        if let value = command.params?.values.first,
            let includeValue = value {
            XCTAssertTrue(includeValue.contains("\"yolo\""))
        } else {
            XCTFail("Should have unwrapped value")
        }
        XCTAssertNil(command.body)

        let user2 = User()
        XCTAssertThrowsError(try user2.fetchCommand(include: nil))
    }

    @MainActor
    func testFetch() async throws {
        try await login()
        MockURLProtocol.removeAll()

        let user = try await User.current()

        var serverResponse = LoginSignupResponse()
        serverResponse.createdAt = user.createdAt
        serverResponse.updatedAt = user.updatedAt?.addingTimeInterval(+300)
        serverResponse.sessionToken = "newValue"
        serverResponse.username = "stop"

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let fetched = try await user.fetch()
        XCTAssertEqual(fetched.objectId, serverResponse.objectId)

        let userFromKeychain = try await BaseParseUser.current()

        XCTAssertEqual(userFromKeychain.objectId, serverResponse.objectId)
    }

    func testFetchAndUpdateCurrentUser() async throws {
        try await testLogin()
        MockURLProtocol.removeAll()
        let user = try await User.current()
        XCTAssertNotNil(user.objectId)

        var userOnServer = user
        userOnServer.createdAt = user.createdAt
        userOnServer.updatedAt = user.updatedAt?.addingTimeInterval(+300)
        userOnServer.customKey = "newValue"

        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder().encode(userOnServer, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let fetched = try await user.fetch(options: [.usePrimaryKey])
        XCTAssert(fetched.hasSameObjectId(as: userOnServer))
        guard let fetchedCreatedAt = fetched.createdAt,
            let fetchedUpdatedAt = fetched.updatedAt else {
                XCTFail("Should unwrap dates")
                return
        }
        guard let originalCreatedAt = user.createdAt,
            let originalUpdatedAt = user.updatedAt else {
                XCTFail("Should unwrap dates")
                return
        }
        XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
        XCTAssertGreaterThan(fetchedUpdatedAt, originalUpdatedAt)
        XCTAssertNil(fetched.ACL)
        XCTAssertEqual(fetched.customKey, userOnServer.customKey)

        // Should be updated in memory
        let updatedCurrentUser = try await User.current()
        XCTAssertEqual(updatedCurrentUser.updatedAt, fetchedUpdatedAt)
        XCTAssertEqual(updatedCurrentUser.customKey, userOnServer.customKey)

        #if !os(Linux) && !os(Android) && !os(Windows)
        // Should be updated in Keychain
        let keychainUser: CurrentUserContainer<User>?
            = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser)
        guard let keychainUpdatedCurrent = keychainUser?.currentUser else {
            XCTFail("Should get object from Keychain")
            return
        }
        XCTAssertEqual(keychainUpdatedCurrent, fetched)
        #endif
    }

    @MainActor
    func testSaveCommand() async throws {
        let user = User()

        let command = try await user.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
    }

    @MainActor
    func testSaveUpdateCommand() async throws {
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId

        let command = try await user.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
    }

    @MainActor
    func testCreateCommand() async throws {
        let user = User()

        let command = await user.createCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
    }

    @MainActor
    func testReplaceCommand() async throws {
        var user = User()
        do {
            _ = try await user.replaceCommand()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.containedIn([.missingObjectId]))
        }

        let objectId = "yarr"
        user.objectId = objectId

        let command = try await user.replaceCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
    }

    @MainActor
    func testUpdateCommand() async throws {
        var user = User()
        do {
            _ = try await user.updateCommand()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.containedIn([.missingObjectId]))
        }

        let objectId = "yarr"
        user.objectId = objectId

        let command = try await user.updateCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PATCH)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
    }

    @MainActor
    func testUpdateCommandUnmodifiedEmail() async throws {
        try await userSignUp()
        let user = try await User.current()
        guard let objectId = user.objectId else {
            XCTFail("Should have current user.")
            return
        }
        XCTAssertNotNil(user.email)
        let command = try await user.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
        XCTAssertNil(command.body?.email)
    }

    @MainActor
    func testUpdateCommandModifiedEmail() async throws {
        try await userSignUp()
        var user = try await User.current()
        guard let objectId = user.objectId else {
            XCTFail("Should have current user.")
            return
        }
        let email = "peace@parse.com"
        user.email = email
        XCTAssertNotNil(user.email)
        let command = try await user.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
        XCTAssertEqual(command.body?.email, email)
    }

    @MainActor
    func testUpdateCommandNotCurrentModifiedEmail() async throws {
        try await userSignUp()
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId
        let email = "peace@parse.com"
        user.email = email
        XCTAssertNotNil(user.email)
        let command = try await user.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
        XCTAssertEqual(command.body?.email, email)
    }

    @MainActor
    func testUpdateCommandCurrentUserModifiedEmail() async throws {
        try await userSignUp()
        var user = try await User.current()
        guard let objectId = user.objectId else {
            XCTFail("Should have current user.")
            return
        }
        let email = "peace@parse.com"
        user.email = email
        let command = try await user.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
        XCTAssertEqual(command.body?.email, email)
    }

    @MainActor
    func testUpdateCommandCurrentUserNotCurrentModifiedEmail() async throws {
        try await userSignUp()
        var user = try await User.current()
        guard let objectId = user.objectId else {
            XCTFail("Should have current user.")
            return
        }
        let email = "peace@parse.com"
        user.email = email
        let command = try await user.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
        XCTAssertEqual(command.body?.email, email)
    }

    @MainActor
    func testSaveCurrent() async throws {
        try await login()
        MockURLProtocol.removeAll()

        var user = try await User.current()
        user.username = "stop"

        var serverResponse = user
        serverResponse.updatedAt = user.updatedAt?.addingTimeInterval(+300)

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let saved = try await user.save()
        XCTAssertEqual(saved.objectId, serverResponse.objectId)

        let userFromKeychain = try await BaseParseUser.current()

        XCTAssertEqual(userFromKeychain.objectId, serverResponse.objectId)
    }

    @MainActor
    func testSave() async throws {
        try await login()
        MockURLProtocol.removeAll()

        var user = User()
        user.username = "stop"

        let current = try await User.current()
        var serverResponse = user
        serverResponse.objectId = "yolo"
        serverResponse.createdAt = current.createdAt

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let saved = try await user.save()
        XCTAssertEqual(saved.objectId, serverResponse.objectId)
    }

    @MainActor
    func testSaveAndUpdateCurrentUser() async throws {
        try await userSignUp()
        let user = try await User.current()
        XCTAssertNotNil(user.objectId)
        XCTAssertNotNil(user.email)
        var userOnServer = user
        userOnServer.createdAt = nil
        userOnServer.updatedAt = user.updatedAt?.addingTimeInterval(+300)

        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder().encode(userOnServer, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let saved = try await user.save(options: [.usePrimaryKey])
        XCTAssert(saved.hasSameObjectId(as: userOnServer))
        XCTAssertEqual(saved.email, user.email)
        guard let savedCreatedAt = saved.createdAt,
            let savedUpdatedAt = saved.updatedAt else {
                XCTFail("Should unwrap dates")
                return
        }
        XCTAssertEqual(savedCreatedAt, user.createdAt)
        XCTAssertEqual(savedUpdatedAt, userOnServer.updatedAt)
        XCTAssertNil(saved.ACL)

        // Should be updated in memory
        let currentUser = try await User.current()
        XCTAssertEqual(currentUser.updatedAt, savedUpdatedAt)
        XCTAssertEqual(currentUser.email, user.email)

        #if !os(Linux) && !os(Android) && !os(Windows)
        // Should be updated in Keychain
        let keychainUser: CurrentUserContainer<User>?
            = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser)
        guard let keychainUpdatedCurrent = keychainUser?.currentUser else {
            XCTFail("Should get object from Keychain")
            return
        }
        XCTAssertEqual(keychainUpdatedCurrent, saved)
        XCTAssertEqual(keychainUser?.currentUser?.email, user.email)
        #endif
    }

    @MainActor
    func testSaveAndUpdateCurrentUserModifiedEmail() async throws {
        try await userSignUp()
        var user = try await User.current()
        XCTAssertNotNil(user.objectId)
        XCTAssertNotNil(user.email)
        user.email = "pease@parse.com"
        var userOnServer = user
        userOnServer.createdAt = nil
        userOnServer.updatedAt = user.updatedAt?.addingTimeInterval(+300)

        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder().encode(userOnServer, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let saved = try await user.save(options: [.usePrimaryKey])
        XCTAssert(saved.hasSameObjectId(as: userOnServer))
        XCTAssertEqual(saved.email, user.email)
        guard let savedCreatedAt = saved.createdAt,
            let savedUpdatedAt = saved.updatedAt else {
                XCTFail("Should unwrap dates")
                return
        }
        XCTAssertEqual(savedCreatedAt, user.createdAt)
        XCTAssertEqual(savedUpdatedAt, userOnServer.updatedAt)
        XCTAssertNil(saved.ACL)

        // Should be updated in memory
        let currentUser = try await User.current()
        XCTAssertEqual(currentUser.updatedAt, savedUpdatedAt)
        XCTAssertEqual(currentUser.email, user.email)

        #if !os(Linux) && !os(Android) && !os(Windows)
        // Should be updated in Keychain
        let keychainUser: CurrentUserContainer<User>?
            = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser)
        guard let keychainUpdatedCurrent = keychainUser?.currentUser else {
            XCTFail("Should get object from Keychain")
            return
        }
        XCTAssertEqual(keychainUpdatedCurrent, saved)
        XCTAssertEqual(keychainUser?.currentUser?.email, user.email)
        #endif
    }

    @MainActor
    func testSaveMutableMergeCurrentUser() async throws {
        // Signup current User
        try await userSignUp()
        let original = try await User.current()
        XCTAssertNotNil(original.objectId)

        var response = original.mergeable
        response.createdAt = nil
        response.updatedAt = Calendar.current.date(byAdding: .init(day: 1), to: Date())

        let encoded: Data!
        do {
            encoded = try response.getEncoder().encode(response, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            response = try response.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        var updated = original.mergeable
        updated.customKey = "beast"
        updated.username = "mode"

        let saved = try await updated.save()
        let nanoSeconds = UInt64(1 * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoSeconds)

        let newCurrentUser = try await User.current()
        XCTAssertTrue(saved.hasSameObjectId(as: newCurrentUser))
        XCTAssertTrue(saved.hasSameObjectId(as: response))
        XCTAssertEqual(saved.customKey, updated.customKey)
        XCTAssertEqual(saved.email, original.email)
        XCTAssertEqual(saved.username, updated.username)
        XCTAssertEqual(saved.emailVerified, original.emailVerified)
        XCTAssertEqual(saved.password, original.password)
        XCTAssertEqual(saved.authData, original.authData)
        XCTAssertEqual(saved.createdAt, original.createdAt)
        XCTAssertEqual(saved.updatedAt, response.updatedAt)
        XCTAssertNil(saved.originalData)
        XCTAssertEqual(saved.customKey, newCurrentUser.customKey)
        XCTAssertEqual(saved.email, newCurrentUser.email)
        XCTAssertEqual(saved.username, newCurrentUser.username)
        XCTAssertEqual(saved.emailVerified, newCurrentUser.emailVerified)
        XCTAssertEqual(saved.password, newCurrentUser.password)
        XCTAssertEqual(saved.authData, newCurrentUser.authData)
        XCTAssertEqual(saved.createdAt, newCurrentUser.createdAt)
        XCTAssertEqual(saved.updatedAt, newCurrentUser.updatedAt)
    }

    @MainActor
    func testCreate() async throws {
        try await login()
        MockURLProtocol.removeAll()

        var user = User()
        user.username = "stop"

        var serverResponse = user
        serverResponse.objectId = "yolo"
        serverResponse.createdAt = Date()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                serverResponse = try serverResponse.getDecoder().decode(User.self, from: encoded)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let saved = try await user.create()
        XCTAssertEqual(saved.objectId, serverResponse.objectId)
        XCTAssertEqual(saved.createdAt, serverResponse.createdAt)
        XCTAssertEqual(saved.updatedAt, serverResponse.createdAt)
    }

    @MainActor
    func testReplaceCreate() async throws {
        try await login()
        MockURLProtocol.removeAll()

        var user = User()
        user.username = "stop"
        user.objectId = "yolo"

        var serverResponse = user
        serverResponse.createdAt = Date()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                serverResponse = try serverResponse.getDecoder().decode(User.self, from: encoded)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let saved = try await user.replace()
        XCTAssertEqual(saved.objectId, serverResponse.objectId)
        XCTAssertEqual(saved.createdAt, serverResponse.createdAt)
        XCTAssertEqual(saved.updatedAt, serverResponse.createdAt)
    }

    @MainActor
    func testReplaceUpdate() async throws {
        try await login()
        MockURLProtocol.removeAll()

        var user = User()
        user.username = "stop"
        user.objectId = "yolo"

        var serverResponse = user
        serverResponse.updatedAt = Date()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                serverResponse = try serverResponse.getDecoder().decode(User.self, from: encoded)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let saved = try await user.replace()
        XCTAssertEqual(saved.objectId, serverResponse.objectId)
        XCTAssertEqual(saved.updatedAt, serverResponse.updatedAt)
    }

    @MainActor
    func testReplaceClientMissingObjectId() async throws {
        var user = User()
        user.customKey = "123"
        do {
            _ = try await user.replace()
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted to ParseError")
                return
            }
            XCTAssertEqual(parseError.code, .missingObjectId)
        }
    }

    @MainActor
    func testUpdate() async throws {
        try await login()
        MockURLProtocol.removeAll()

        var user = User()
        user.username = "stop"
        user.objectId = "yolo"

        var serverResponse = user
        serverResponse.updatedAt = Date()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                serverResponse = try serverResponse.getDecoder().decode(User.self, from: encoded)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let saved = try await user.update()
        XCTAssertEqual(saved.objectId, serverResponse.objectId)
        XCTAssertEqual(saved.updatedAt, serverResponse.updatedAt)
    }

    @MainActor
    func testUpdateDefaultMerge() async throws {
        try await login()
        MockURLProtocol.removeAll()

        var user = UserDefaultMerge()
        user.username = "stop"
        user.objectId = "yolo"

        var serverResponse = user
        serverResponse.updatedAt = Date()
        serverResponse.customKey = "be"

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                serverResponse = try serverResponse.getDecoder().decode(UserDefaultMerge.self, from: encoded)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        user = user.set(\.customKey, to: "be")
        let saved = try await user.update()
        XCTAssertEqual(saved.objectId, serverResponse.objectId)
        XCTAssertEqual(saved.updatedAt, serverResponse.updatedAt)
    }

    @MainActor
    func testUpdateClientMissingObjectId() async throws {
        var user = User()
        user.customKey = "123"
        do {
            _ = try await user.update()
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted to ParseError")
                return
            }
            XCTAssertEqual(parseError.code, .missingObjectId)
        }
    }

    func testUpdateMutableMergeCurrentUser() async throws {
        // Signup current User
        try await login()
        MockURLProtocol.removeAll()

        let original = try await User.current()
        var originalResponse = original.mergeable
        originalResponse.createdAt = nil
        originalResponse.updatedAt = Calendar.current.date(byAdding: .init(day: 1), to: Date())

        let encoded: Data!
        do {
            encoded = try originalResponse.getEncoder().encode(originalResponse, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            originalResponse = try originalResponse.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        let response = originalResponse
        var originalUpdated = original.mergeable
        originalUpdated.customKey = "beast"
        originalUpdated.username = "mode"
        let updated = originalUpdated

        let saved = try await updated.update()
        let newCurrentUser = try await User.current()
        XCTAssertTrue(saved.hasSameObjectId(as: newCurrentUser))
        XCTAssertTrue(saved.hasSameObjectId(as: response))
        XCTAssertEqual(saved.customKey, updated.customKey)
        XCTAssertEqual(saved.email, original.email)
        XCTAssertEqual(saved.username, updated.username)
        XCTAssertEqual(saved.emailVerified, original.emailVerified)
        XCTAssertEqual(saved.password, original.password)
        XCTAssertEqual(saved.authData, original.authData)
        XCTAssertEqual(saved.createdAt, original.createdAt)
        XCTAssertEqual(saved.updatedAt, response.updatedAt)
        XCTAssertNil(saved.originalData)
        XCTAssertEqual(saved.customKey, newCurrentUser.customKey)
        XCTAssertEqual(saved.email, newCurrentUser.email)
        XCTAssertEqual(saved.username, newCurrentUser.username)
        XCTAssertEqual(saved.emailVerified, newCurrentUser.emailVerified)
        XCTAssertEqual(saved.password, newCurrentUser.password)
        XCTAssertEqual(saved.authData, newCurrentUser.authData)
        XCTAssertEqual(saved.createdAt, newCurrentUser.createdAt)
        XCTAssertEqual(saved.updatedAt, newCurrentUser.updatedAt)
    }

    func testUpdateMutableMergeCurrentUserDefault() async throws {
        // Signup current User
        try await login()
        MockURLProtocol.removeAll()

        let original = try await UserDefault.current()
        var originalResponse = original.mergeable
        originalResponse.createdAt = nil
        originalResponse.updatedAt = Calendar.current.date(byAdding: .init(day: 1), to: Date())

        let encoded: Data!
        do {
            encoded = try originalResponse.getEncoder().encode(originalResponse, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            originalResponse = try originalResponse.getDecoder().decode(UserDefault.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        let response = originalResponse
        var originalUpdated = original.mergeable
        originalUpdated.username = "mode"
        let updated = originalUpdated

        let saved = try await updated.update()
        let newCurrentUser = try await User.current()
        XCTAssertTrue(saved.hasSameObjectId(as: newCurrentUser))
        XCTAssertTrue(saved.hasSameObjectId(as: response))
        XCTAssertEqual(saved.email, original.email)
        XCTAssertEqual(saved.username, updated.username)
        XCTAssertEqual(saved.emailVerified, original.emailVerified)
        XCTAssertEqual(saved.password, original.password)
        XCTAssertEqual(saved.authData, original.authData)
        XCTAssertEqual(saved.createdAt, original.createdAt)
        XCTAssertEqual(saved.updatedAt, response.updatedAt)
        XCTAssertNil(saved.originalData)
        XCTAssertEqual(saved.email, newCurrentUser.email)
        XCTAssertEqual(saved.username, newCurrentUser.username)
        XCTAssertEqual(saved.emailVerified, newCurrentUser.emailVerified)
        XCTAssertEqual(saved.password, newCurrentUser.password)
        XCTAssertEqual(saved.authData, newCurrentUser.authData)
        XCTAssertEqual(saved.createdAt, newCurrentUser.createdAt)
        XCTAssertEqual(saved.updatedAt, newCurrentUser.updatedAt)
    }

    @MainActor
    func testSaveWithDefaultACL() async throws {
        try await userSignUp()
        let original = try await User.current()
        guard let userObjectId = original.objectId else {
            XCTFail("Should have objectId")
            return
        }
        let defaultACL = try await ParseACL.setDefaultACL(ParseACL(),
                                                          withAccessForCurrentUser: true)

        let user = User()
        var userOnServer = user
        userOnServer.objectId = "hello"
        userOnServer.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder().encode(userOnServer, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let saved = try await user.save(options: [.usePrimaryKey])
        XCTAssert(saved.hasSameObjectId(as: userOnServer))
        guard let savedCreatedAt = saved.createdAt,
            let savedUpdatedAt = saved.updatedAt else {
                XCTFail("Should unwrap dates")
                return
        }
        guard let originalCreatedAt = userOnServer.createdAt else {
                XCTFail("Should unwrap dates")
                return
        }
        XCTAssertEqual(savedCreatedAt, originalCreatedAt)
        XCTAssertEqual(savedUpdatedAt, originalCreatedAt)
        XCTAssertNotNil(saved.ACL)
        XCTAssertEqual(saved.ACL?.publicRead, defaultACL.publicRead)
        XCTAssertEqual(saved.ACL?.publicWrite, defaultACL.publicWrite)
        XCTAssertTrue(defaultACL.getReadAccess(objectId: userObjectId))
        XCTAssertTrue(defaultACL.getWriteAccess(objectId: userObjectId))
    }

    @MainActor
    func testUpdateWithDefaultACL() async throws {
        try await userSignUp()
        _ = try await ParseACL.setDefaultACL(ParseACL(),
                                             withAccessForCurrentUser: true)
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId
        user.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        user.ACL = nil

        var userOnServer = user
        userOnServer.updatedAt = Date()

        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder().encode(userOnServer, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        let saved = try await user.save()
        guard let savedUpdatedAt = saved.updatedAt else {
            XCTFail("Should unwrap dates")
            return
        }
        guard let originalUpdatedAt = user.updatedAt else {
            XCTFail("Should unwrap dates")
            return
        }
        XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
        XCTAssertNil(saved.ACL)
    }

    func updateAsync(user: User, userOnServer: User, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Update user1")
        user.save(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                guard let savedUpdatedAt = saved.updatedAt else {
                    XCTFail("Should unwrap dates")
                    expectation1.fulfill()
                    return
                }
                guard let originalUpdatedAt = user.updatedAt else {
                    XCTFail("Should unwrap dates")
                    expectation1.fulfill()
                    return
                }
                XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(saved.ACL)
                if callbackQueue.qos == .userInteractive {
                    XCTAssertTrue(Thread.isMainThread)
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "Update user2")
        user.save(options: [.usePrimaryKey], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                guard let savedUpdatedAt = saved.updatedAt else {
                    XCTFail("Should unwrap dates")
                    expectation2.fulfill()
                    return
                }
                guard let originalUpdatedAt = user.updatedAt else {
                    XCTFail("Should unwrap dates")
                    expectation2.fulfill()
                    return
                }

                XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(saved.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func testThreadSafeUpdateAsync() {
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId
        user.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        user.ACL = nil

        var userOnServer = user
        userOnServer.updatedAt = Date()
        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder().encode(userOnServer, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            let delay = MockURLResponse.addRandomDelay(2)
            return MockURLResponse(data: encoded, statusCode: 200, delay: delay)
        }

        DispatchQueue.concurrentPerform(iterations: 3) { _ in
            self.updateAsync(user: user, userOnServer: userOnServer, callbackQueue: .global(qos: .background))
        }
    }
    #endif

    @MainActor
    func testUserCustomValuesSavedToKeychain() async throws {
        try await testLogin()
        let customField = "Changed"
        var user = try await User.current()
        user.customKey = customField
        try await User.setCurrent(user)
        #if !os(Linux) && !os(Android) && !os(Windows)
        let keychainUser: CurrentUserContainer<User>?
            = try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser)
        XCTAssertEqual(keychainUser?.currentUser?.customKey, customField)
        #endif
    }

    @MainActor
    func testDeleteCommand() async throws {
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId
        let command = try user.deleteCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users/\(objectId)")
        XCTAssertEqual(command.method, API.Method.DELETE)
        XCTAssertNil(command.body)

        let user2 = User()
        XCTAssertThrowsError(try user2.deleteCommand())
    }

    @MainActor
    func testDelete() async throws {
        try await login()
        MockURLProtocol.removeAll()

        let user = try await User.current()

        let serverResponse = NoBody()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        _ = try await user.delete()

        do {
            _ = try await BaseParseUser.current()
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted to ParseError")
                return
            }
            XCTAssertTrue(parseError.message.contains("no current"))
        }
    }

    @MainActor
    func testDeleteError() async throws {
        try await login()
        MockURLProtocol.removeAll()

        let user = try await User.current()
        let serverResponse = ParseError(code: .objectNotFound, message: "Not found")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        do {
            _ = try await user.delete()
            XCTFail("Should have thrown error")
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("Should be ParseError")
                return
            }
            XCTAssertEqual(error.message, serverResponse.message)
        }
        XCTAssertNotNil(BaseParseUser.current)
    }

    // swiftlint:disable:next function_body_length
    @MainActor func testFetchAll() async throws {
        try await login()
        MockURLProtocol.removeAll()

        var user = try await User.current()
        user.updatedAt = user.updatedAt?.addingTimeInterval(+300)
        user.customKey = "newValue"
        let userOnServer = QueryResponse<User>(results: [user], count: 1)

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
            // Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(user)
            user = try user.getDecoder().decode(User.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let fetched = try await [user].fetchAll()
        let current = try await User.current()
        guard let updatedCurrentDate = current.updatedAt else {
            XCTFail("Should unwrap current date")
            return
        }
        for object in fetched {
            switch object {
            case .success(let fetched):
                XCTAssert(fetched.hasSameObjectId(as: user))
                guard let fetchedCreatedAt = fetched.createdAt,
                    let fetchedUpdatedAt = fetched.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt = user.createdAt,
                    let originalUpdatedAt = user.updatedAt,
                    let serverUpdatedAt = user.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
                XCTAssertEqual(fetchedUpdatedAt, serverUpdatedAt)
                XCTAssertEqual(current.customKey, user.customKey)

                // Should be updated in memory
                XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)

                #if !os(Linux) && !os(Android) && !os(Windows)
                // Should be updated in Keychain
                guard let keychainUser: CurrentUserContainer<BaseParseUser>
                    = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser),
                    let keychainUpdatedCurrentDate = keychainUser.currentUser?.updatedAt else {
                        XCTFail("Should get object from Keychain")
                    return
                }
                XCTAssertEqual(keychainUpdatedCurrentDate, serverUpdatedAt)
                #endif
            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
        }
    }

    // swiftlint:disable:next function_body_length
    @MainActor func testSaveAll() async throws {
        try await login()
        MockURLProtocol.removeAll()

        var user = try await User.current()
        user.createdAt = nil
        user.updatedAt = user.updatedAt?.addingTimeInterval(+300)
        user.customKey = "newValue"
        let userOnServer = [BatchResponseItem<User>(success: user, error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
            // Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(user)
            user = try user.getDecoder().decode(User.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let saved = try await [user].saveAll()
        let current = try await User.current()
        guard let updatedCurrentDate = current.updatedAt else {
            XCTFail("Should unwrap current date")
            return
        }
        for object in saved {
            switch object {
            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: user))
                guard let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalUpdatedAt = user.updatedAt,
                    let serverUpdatedAt = user.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                XCTAssertEqual(savedUpdatedAt, serverUpdatedAt)
                XCTAssertEqual(current.customKey, user.customKey)

                // Should be updated in memory
                XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)

                #if !os(Linux) && !os(Android) && !os(Windows)
                // Should be updated in Keychain
                guard let keychainUser: CurrentUserContainer<BaseParseUser>
                    = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser),
                    let keychainUpdatedCurrentDate = keychainUser.currentUser?.updatedAt else {
                        XCTFail("Should get object from Keychain")
                    return
                }
                XCTAssertEqual(keychainUpdatedCurrentDate, serverUpdatedAt)
                #endif
            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func testCreateAll() async throws {
        try await login()
        MockURLProtocol.removeAll()

        var user = User()
        user.username = "stop"

        var userOnServer = user
        userOnServer.objectId = "yolo"
        userOnServer.createdAt = Date()

        let serverResponse = [BatchResponseItem<User>(success: userOnServer, error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
            // Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(userOnServer)
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let saved = try await [user].createAll()
        saved.forEach {
            switch $0 {
            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: userOnServer))
                guard let savedCreatedAt = saved.createdAt,
                    let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt = userOnServer.createdAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                XCTAssertEqual(savedUpdatedAt, originalCreatedAt)

            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func testReplaceAllCreate() async throws {
        try await login()
        MockURLProtocol.removeAll()

        var user = User()
        user.username = "stop"
        user.objectId = "yolo"

        var userOnServer = user
        userOnServer.createdAt = Date()

        let serverResponse = [BatchResponseItem<User>(success: userOnServer, error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
            // Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(userOnServer)
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let saved = try await [user].replaceAll()
        saved.forEach {
            switch $0 {
            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: userOnServer))
                XCTAssertEqual(saved.createdAt, userOnServer.createdAt)
                XCTAssertEqual(saved.updatedAt, userOnServer.createdAt)
                XCTAssertEqual(saved.username, userOnServer.username)

            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func testReplaceAllUpdate() async throws {
        try await login()
        MockURLProtocol.removeAll()

        var user = User()
        user.username = "stop"
        user.objectId = "yolo"

        var userOnServer = user
        userOnServer.updatedAt = Date()

        let serverResponse = [BatchResponseItem<User>(success: userOnServer, error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
            // Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(userOnServer)
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let saved = try await [user].replaceAll()
        saved.forEach {
            switch $0 {
            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: userOnServer))
                guard let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalUpdatedAt = userOnServer.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                XCTAssertEqual(saved.username, userOnServer.username)

            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func testUpdateAll() async throws {
        try await login()
        MockURLProtocol.removeAll()

        var user = User()
        user.username = "stop"
        user.objectId = "yolo"

        var userOnServer = user
        userOnServer.updatedAt = Date()

        let serverResponse = [BatchResponseItem<User>(success: userOnServer, error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
            // Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(userOnServer)
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let saved = try await [user].updateAll()
        saved.forEach {
            switch $0 {
            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: userOnServer))
                guard let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalUpdatedAt = userOnServer.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                XCTAssertEqual(saved.username, userOnServer.username)

            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func testDeleteAll() async throws {
        try await login()
        MockURLProtocol.removeAll()

        let user = try await User.current()

        let userOnServer = [BatchResponseItem<NoBody>(success: NoBody(), error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        try await [user].deleteAll()
            .forEach {
                if case let .failure(error) = $0 {
                    XCTFail("Should have deleted: \(error.localizedDescription)")
                }
        }
    }
}
// swiftlint:disable:this file_length
