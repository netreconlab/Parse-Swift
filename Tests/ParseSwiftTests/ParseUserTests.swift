//
//  ParseUserTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 7/21/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

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
            self.emailVerified = false
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

    func testFetchCommand() {
        var user = User()
        XCTAssertThrowsError(try user.fetchCommand(include: nil))
        let objectId = "yarr"
        user.objectId = objectId
        do {
            let command = try user.fetchCommand(include: nil)
            XCTAssertNotNil(command)
            XCTAssertEqual(command.path.urlComponent, "/users/\(objectId)")
            XCTAssertEqual(command.method, API.Method.GET)
            XCTAssertNil(command.params)
            XCTAssertNil(command.body)
        } catch {
            XCTFail(error.localizedDescription)
        }

        let user2 = User()
        XCTAssertThrowsError(try user2.fetchCommand(include: nil))
    }

    func testFetchIncludeCommand() {
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId
        let includeExpected = ["include": "[\"yolo\", \"test\"]"]
        do {
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
        } catch {
            XCTFail(error.localizedDescription)
        }

        let user2 = User()
        XCTAssertThrowsError(try user2.fetchCommand(include: nil))
    }

    func testFetch() async throws { // swiftlint:disable:this function_body_length
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId

        var userOnServer = user
        userOnServer.createdAt = Date()
        userOnServer.updatedAt = userOnServer.createdAt
        userOnServer.ACL = nil
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

        do {
            let fetched = try await user.fetch()
            XCTAssert(fetched.hasSameObjectId(as: userOnServer))
            guard let fetchedCreatedAt = fetched.createdAt,
                let fetchedUpdatedAt = fetched.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = userOnServer.createdAt,
                let originalUpdatedAt = userOnServer.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
            XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(fetched.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let fetched = try await user.fetch(options: [.usePrimaryKey])
            XCTAssert(fetched.hasSameObjectId(as: userOnServer))
            guard let fetchedCreatedAt = fetched.createdAt,
                let fetchedUpdatedAt = fetched.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = userOnServer.createdAt,
                let originalUpdatedAt = userOnServer.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
            XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(fetched.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // swiftlint:disable:next function_body_length
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

        do {
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

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testFetchAsyncAndUpdateCurrentUser() async throws { // swiftlint:disable:this function_body_length
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

        let expectation1 = XCTestExpectation(description: "Fetch user1")
        user.fetch(options: [], callbackQueue: .global(qos: .background)) { result in

            switch result {
            case .success(let fetched):
                XCTAssert(fetched.hasSameObjectId(as: userOnServer))
                guard let fetchedCreatedAt = fetched.createdAt,
                    let fetchedUpdatedAt = fetched.updatedAt else {
                        XCTFail("Should unwrap dates")
                    expectation1.fulfill()
                        return
                }
                guard let originalCreatedAt = user.createdAt,
                    let originalUpdatedAt = user.updatedAt else {
                        XCTFail("Should unwrap dates")
                    expectation1.fulfill()
                        return
                }
                XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                XCTAssertGreaterThan(fetchedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(fetched.ACL)

                let immutableUserOnServer = userOnServer
                Task {
                    do {
                        // Should be updated in memory
                        let updatedCurrentUser = try await User.current()
                        XCTAssertEqual(updatedCurrentUser.customKey, immutableUserOnServer.customKey)
                        XCTAssertEqual(updatedCurrentUser.updatedAt, fetchedUpdatedAt)

                        #if !os(Linux) && !os(Android) && !os(Windows)
                        // Should be updated in Keychain
                        let keychainUser: CurrentUserContainer<User>?
                            = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser)
                        guard let keychainUpdatedCurrent = keychainUser?.currentUser else {
                            XCTFail("Should get object from Keychain")
                            return
                        }
                        XCTAssertEqual(keychainUpdatedCurrent, updatedCurrentUser)
                        #endif
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

    // swiftlint:disable:next function_body_length
    func fetchAsync(user: User, userOnServer: User) {

        let expectation1 = XCTestExpectation(description: "Fetch user1")
        user.fetch(options: [], callbackQueue: .global(qos: .background)) { result in

            switch result {

            case .success(let fetched):
                XCTAssert(fetched.hasSameObjectId(as: userOnServer))
                guard let fetchedCreatedAt = fetched.createdAt,
                    let fetchedUpdatedAt = fetched.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                }
                guard let originalCreatedAt = userOnServer.createdAt,
                    let originalUpdatedAt = userOnServer.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                }
                XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(fetched.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "Fetch user2")
        user.fetch(options: [.sessionToken("")], callbackQueue: .global(qos: .background)) { result in

            switch result {

            case .success(let fetched):
                XCTAssert(fetched.hasSameObjectId(as: userOnServer))
                guard let fetchedCreatedAt = fetched.createdAt,
                    let fetchedUpdatedAt = fetched.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation2.fulfill()
                        return
                }
                guard let originalCreatedAt = userOnServer.createdAt,
                    let originalUpdatedAt = userOnServer.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation2.fulfill()
                        return
                }
                XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(fetched.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func testThreadSafeFetchAsync() {
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId

        var userOnServer = user
        userOnServer.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        userOnServer.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        userOnServer.ACL = nil
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
            self.fetchAsync(user: user, userOnServer: userOnServer)
        }
    }
    #endif

    func testSaveCommand() async throws {
        let user = User()

        let command = try await user.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
    }

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

    func testCreateCommand() async throws {
        let user = User()

        let command = await user.createCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
    }

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

        do {
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

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

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

        do {
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

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

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

        do {
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
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveAsyncAndUpdateCurrentUser() async throws { // swiftlint:disable:this function_body_length
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

        let expectation1 = XCTestExpectation(description: "Fetch user1")
        user.save(options: [], callbackQueue: .global(qos: .background)) { result in

            switch result {
            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: userOnServer))
                XCTAssertEqual(saved.email, user.email)
                guard let savedCreatedAt = saved.createdAt,
                    let savedUpdatedAt = saved.updatedAt else {
                    XCTFail("Should unwrap dates")
                    expectation1.fulfill()
                    return
                }
                XCTAssertEqual(savedCreatedAt, user.createdAt)
                XCTAssertEqual(savedUpdatedAt, userOnServer.updatedAt)
                XCTAssertNil(saved.ACL)

                // Should be updated in memory
                Task {
                    do {
                        let updatedCurrentUser = try await User.current()
                        XCTAssertEqual(updatedCurrentUser.updatedAt, savedUpdatedAt)
                        XCTAssertEqual(updatedCurrentUser.email, user.email)

                        #if !os(Linux) && !os(Android) && !os(Windows)
                        // Should be updated in Keychain
                        let keychainUser: CurrentUserContainer<User>?
                            = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser)
                        guard let keychainUpdatedCurrent = keychainUser?.currentUser else {
                            XCTFail("Should get object from Keychain")
                            return
                        }
                        XCTAssertEqual(keychainUpdatedCurrent, updatedCurrentUser)
                        XCTAssertEqual(keychainUser?.currentUser?.email, user.email)
                        #endif
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

    func testSaveAsyncAndUpdateCurrentUserModifiedEmail() async throws { // swiftlint:disable:this function_body_length
        try await userSignUp()
        let original = try await User.current()
        var user = original
        XCTAssertNotNil(user.objectId)
        user.email = "pease@parse.com"
        XCTAssertNotEqual(original.email, user.email)
        var userOnServer = user
        userOnServer.createdAt = nil
        userOnServer.updatedAt = original.updatedAt?.addingTimeInterval(+300)

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

        let expectation1 = XCTestExpectation(description: "Fetch user1")
        user.save(options: [], callbackQueue: .global(qos: .background)) { result in

            switch result {
            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: userOnServer))
                XCTAssertEqual(saved.email, user.email)
                guard let savedCreatedAt = saved.createdAt,
                    let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                    expectation1.fulfill()
                        return
                }
                XCTAssertEqual(savedCreatedAt, user.createdAt)
                XCTAssertEqual(savedUpdatedAt, userOnServer.updatedAt)
                XCTAssertNil(saved.ACL)

                // Should be updated in memory
                let originalUser = user
                Task {
                    do {
                        let updatedCurrentUser = try await User.current()
                        XCTAssertEqual(updatedCurrentUser.updatedAt, savedUpdatedAt)
                        XCTAssertEqual(updatedCurrentUser.email, originalUser.email)

                        #if !os(Linux) && !os(Android) && !os(Windows)
                        // Should be updated in Keychain
                        // Should be updated in Keychain
                        let keychainUser: CurrentUserContainer<User>?
                            = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser)
                        guard let keychainUpdatedCurrent = keychainUser?.currentUser else {
                            XCTFail("Should get object from Keychain")
                            return
                        }
                        XCTAssertEqual(keychainUpdatedCurrent, updatedCurrentUser)
                        XCTAssertEqual(keychainUser?.currentUser?.email, originalUser.email)
                        #endif

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

    func testUpdate() async throws {
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
        do {
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
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let saved = try await user.save(options: [.usePrimaryKey])
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
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

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

        do {
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
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

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
        do {
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
        } catch {
            XCTFail(error.localizedDescription)
        }
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

    func testUpdateAsyncMainQueue() {
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

        self.updateAsync(user: user, userOnServer: userOnServer, callbackQueue: .main)
    }
    #endif

    func testSignupCommandWithBody() throws {
        let body = SignupLoginBody(username: "test", password: "user")
        let command = try User.signupCommand(body: body)
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertEqual(command.body?.username, body.username)
        XCTAssertEqual(command.body?.password, body.password)
    }

    func testSignupCommandNoBody() throws {
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

    func testUserSignUp() async throws {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        let signedUp = try await User.signup(username: loginUserName, password: loginPassword)
        XCTAssertNotNil(signedUp)
        XCTAssertNotNil(signedUp.createdAt)
        XCTAssertNotNil(signedUp.updatedAt)
        XCTAssertNotNil(signedUp.email)
        XCTAssertNotNil(signedUp.emailVerified)
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
        XCTAssertNotNil(userFromKeychain.email)
        XCTAssertNotNil(userFromKeychain.username)
        XCTAssertNil(userFromKeychain.password)
        XCTAssertNotNil(userFromKeychain.objectId)
        XCTAssertNil(userFromKeychain.ACL)
    }

    func testUserSignUpNoBody() async throws {
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

    func signUpAsync(loginResponse: LoginSignupResponse, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Signup user1")
        User.signup(username: loginUserName,
                    password: loginPassword,
                    callbackQueue: callbackQueue) { result in
            switch result {

            case .success(let signedUp):
                XCTAssertNotNil(signedUp.createdAt)
                XCTAssertNotNil(signedUp.updatedAt)
                XCTAssertNotNil(signedUp.email)
                XCTAssertNotNil(signedUp.username)
                XCTAssertNil(signedUp.password)
                XCTAssertNotNil(signedUp.objectId)
                XCTAssertNotNil(signedUp.customKey)
                XCTAssertNil(signedUp.ACL)

                Task {
                    do {
                        let userFromKeychain = try await BaseParseUser.current()
                        XCTAssertNotNil(userFromKeychain.createdAt)
                        XCTAssertNotNil(userFromKeychain.updatedAt)
                        XCTAssertNotNil(userFromKeychain.email)
                        XCTAssertNotNil(userFromKeychain.username)
                        XCTAssertNil(userFromKeychain.password)
                        XCTAssertNotNil(userFromKeychain.objectId)
                        let sessionToken = try? await User.sessionToken()
                        XCTAssertNotNil(sessionToken)
                        XCTAssertNil(userFromKeychain.ACL)
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

    func testSignUpAsyncMainQueue() {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        self.signUpAsync(loginResponse: loginResponse, callbackQueue: .main)
    }

    func signUpAsyncNoBody(loginResponse: LoginSignupResponse, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Signup user1")
        var user = User()
        user.username = loginUserName
        user.password = loginPassword
        user.customKey = "blah"
        user.signup(callbackQueue: callbackQueue) { result in
            switch result {

            case .success(let signedUp):
                XCTAssertNotNil(signedUp.createdAt)
                XCTAssertNotNil(signedUp.updatedAt)
                XCTAssertNil(signedUp.email)
                XCTAssertNotNil(signedUp.username)
                XCTAssertNil(signedUp.password)
                XCTAssertNotNil(signedUp.objectId)
                XCTAssertNotNil(signedUp.customKey)
                XCTAssertNil(signedUp.ACL)

                Task {
                    do {
                        let userFromKeychain = try await BaseParseUser.current()
                        XCTAssertNotNil(userFromKeychain.createdAt)
                        XCTAssertNotNil(userFromKeychain.updatedAt)
                        XCTAssertNil(userFromKeychain.email)
                        XCTAssertNotNil(userFromKeychain.username)
                        XCTAssertNil(userFromKeychain.password)
                        XCTAssertNotNil(userFromKeychain.objectId)
                        let sessionToken = try? await User.sessionToken()
                        XCTAssertNotNil(sessionToken)
                        XCTAssertNil(userFromKeychain.ACL)
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

    func testSignUpAsyncMainQueueNoBody() {
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

        self.signUpAsyncNoBody(loginResponse: loginResponse, callbackQueue: .main)
    }

    func testLoginCommand() {
        let command = User.loginCommand(username: "test", password: "user")
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/login")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNotNil(command.body)
    }

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
        let loggedIn = try await User.login(username: loginUserName, password: loginPassword)
        XCTAssertNotNil(loggedIn)
        XCTAssertNotNil(loggedIn.createdAt)
        XCTAssertNotNil(loggedIn.updatedAt)
        XCTAssertNotNil(loggedIn.email)
        XCTAssertNotNil(loggedIn.username)
        XCTAssertNil(loggedIn.password)
        XCTAssertNotNil(loggedIn.objectId)
        let sessionToken = try? await User.sessionToken()
        XCTAssertNotNil(sessionToken)
        XCTAssertNotNil(loggedIn.customKey)
        XCTAssertNil(loggedIn.ACL)

        let userFromKeychain = try await BaseParseUser.current()

        XCTAssertNotNil(userFromKeychain.createdAt)
        XCTAssertNotNil(userFromKeychain.updatedAt)
        XCTAssertNotNil(userFromKeychain.email)
        XCTAssertNotNil(userFromKeychain.username)
        XCTAssertNil(userFromKeychain.password)
        XCTAssertNotNil(userFromKeychain.objectId)
        XCTAssertNil(userFromKeychain.ACL)
    }

    func loginAsync(loginResponse: LoginSignupResponse, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Login user")
        User.login(username: loginUserName, password: loginPassword,
                   callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let loggedIn):
                XCTAssertNotNil(loggedIn.createdAt)
                XCTAssertNotNil(loggedIn.updatedAt)
                XCTAssertNotNil(loggedIn.email)
                XCTAssertNotNil(loggedIn.username)
                XCTAssertNil(loggedIn.password)
                XCTAssertNotNil(loggedIn.objectId)
                XCTAssertNotNil(loggedIn.customKey)
                XCTAssertNil(loggedIn.ACL)

                Task {
                    do {
                        let userFromKeychain = try await BaseParseUser.current()
                        XCTAssertNotNil(userFromKeychain.createdAt)
                        XCTAssertNotNil(userFromKeychain.updatedAt)
                        XCTAssertNotNil(userFromKeychain.email)
                        XCTAssertNotNil(userFromKeychain.username)
                        XCTAssertNil(userFromKeychain.password)
                        XCTAssertNotNil(userFromKeychain.objectId)
                        let sessionToken = try? await User.sessionToken()
                        XCTAssertNotNil(sessionToken)
                        XCTAssertNil(userFromKeychain.ACL)
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

    func testLoginAsyncMainQueue() {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        self.loginAsync(loginResponse: loginResponse, callbackQueue: .main)
    }

    func testLogutCommand() {
        let command = User.logoutCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/logout")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.body)
    }

    func testLogout() async throws {
        try await testLogin()
        MockURLProtocol.removeAll()

        let logoutResponse = NoBody()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(logoutResponse)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        let oldInstallationId = try await BaseParseInstallation.current().installationId
        try await User.logout()
        do {
            _ = try await BaseParseUser.current()
            XCTFail("User was not deleted from Keychain during logout")
        } catch {
            XCTAssertTrue(error.containedIn([.otherCause]))
        }

        let nanoSeconds = UInt64(1 * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoSeconds)
        let installationFromKeychain = try await BaseParseInstallation.current()
        if installationFromKeychain.installationId == oldInstallationId
            || installationFromKeychain.installationId == nil {
            XCTFail("""
                "\(installationFromKeychain) was not deleted then created in
                Keychain during logout
            """)
        }
    }

    func logoutAsync(callbackQueue: DispatchQueue) async throws {

        let expectation1 = XCTestExpectation(description: "Logout user1")

        let oldInstallationId = try await BaseParseInstallation.current().installationId

        User.logout(callbackQueue: callbackQueue) { result in

            switch result {

            case .success:
                Task {
                    do {
                        do {
                            _ = try await BaseParseUser.current()
                            XCTFail("Should have thrown error")
                        } catch {
                            XCTAssertTrue(error.containedIn([.otherCause]))
                        }
                        let nanoSeconds = UInt64(1 * 1_000_000_000)
                        try await Task.sleep(nanoseconds: nanoSeconds)

                        if let installationFromMemory: CurrentInstallationContainer<BaseParseInstallation>
                            = try? await ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentInstallation) {

                            if installationFromMemory.installationId == oldInstallationId
                                || installationFromMemory.installationId == nil {
                                XCTFail("\(installationFromMemory) was not deleted & recreated in memory during logout")
                            }
                        } else {
                            XCTFail("Should have a new installation")
                        }

                        #if !os(Linux) && !os(Android) && !os(Windows)
                        if let installationFromKeychain: CurrentInstallationContainer<BaseParseInstallation>
                            = try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) {
                            if installationFromKeychain.installationId == oldInstallationId
                                || installationFromKeychain.installationId == nil {
                                // swiftlint:disable:next line_length
                                XCTFail("\(installationFromKeychain) was not deleted & recreated in Keychain during logout")
                            }
                        } else {
                            XCTFail("Should have a new installation")
                        }
                        #endif
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

    func testLogoutAsyncMainQueue() async throws {
        try await testLogin()
        MockURLProtocol.removeAll()

        let logoutResponse = NoBody()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(logoutResponse)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        try await self.logoutAsync(callbackQueue: .main)
    }

    func testPasswordResetCommand() throws {
        let body = EmailBody(email: "hello@parse.org")
        let command = User.passwordResetCommand(email: body.email)
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/requestPasswordReset")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertEqual(command.body?.email, body.email)
    }

    func testPasswordReset() async throws {
        let response = NoBody()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        do {
            try await User.passwordReset(email: "hello@parse.org")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testPasswordResetError() async throws {

        let parseError = ParseError(code: .internalServer, message: "Object not found")

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(parseError)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        do {
            try await User.passwordReset(email: "hello@parse.org")
            XCTFail("Should have thrown ParseError")
        } catch {
            if let error = error as? ParseError {
                XCTAssertEqual(error.code, parseError.code)
            } else {
                XCTFail("Should have thrown ParseError")
            }
        }
    }

    func passwordResetAsync(callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Logout user1")
        User.passwordReset(email: "hello@parse.org", callbackQueue: callbackQueue) { result in

            if case let .failure(error) = result {
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 10.0)
    }

    func testPasswordResetMainQueue() {
        let response = NoBody()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        self.passwordResetAsync(callbackQueue: .main)
    }

    func passwordResetAsyncError(parseError: ParseError, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Logout user1")
        User.passwordReset(email: "hello@parse.org", callbackQueue: callbackQueue) { result in

            if case let .failure(error) = result {
                XCTAssertEqual(error.code, parseError.code)
            } else {
                XCTFail("Should have thrown ParseError")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 10.0)
    }

    func testPasswordResetMainQueueError() {
        let parseError = ParseError(code: .internalServer, message: "Object not found")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(parseError)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        self.passwordResetAsyncError(parseError: parseError, callbackQueue: .main)
    }

    func testVerifyPasswordCommandPOST() throws {
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

    func testVerifyPasswordCommandGET() throws {
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

    func testVerificationEmailRequestCommand() throws {
        let body = EmailBody(email: "hello@parse.org")
        let command = User.verificationEmailCommand(email: body.email)
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/verificationEmailRequest")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertEqual(command.body?.email, body.email)
    }

    func testVerificationEmailRequestReset() async throws {
        let response = NoBody()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        do {
            try await User.verificationEmail(email: "hello@parse.org")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testVerificationEmailRequestError() async throws {

        let parseError = ParseError(code: .internalServer, message: "Object not found")

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(parseError)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        do {
            try await User.verificationEmail(email: "hello@parse.org")
            XCTFail("Should have thrown ParseError")
        } catch {
            if let error = error as? ParseError {
                XCTAssertEqual(error.code, parseError.code)
            } else {
                XCTFail("Should have thrown ParseError")
            }
        }
    }

    func verificationEmailAsync(callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Logout user1")
        User.verificationEmail(email: "hello@parse.org", callbackQueue: callbackQueue) { result in

            if case let .failure(error) = result {
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 10.0)
    }

    func testVerificationEmailRequestMainQueue() {
        let response = NoBody()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        self.verificationEmailAsync(callbackQueue: .main)
    }

    func verificationEmailAsyncError(parseError: ParseError, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Logout user1")
        User.verificationEmail(email: "hello@parse.org", callbackQueue: callbackQueue) { result in

            if case let .failure(error) = result {
                XCTAssertEqual(error.code, parseError.code)
            } else {
                XCTFail("Should have thrown ParseError")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 10.0)
    }

    func testVerificationEmailRequestMainQueueError() {
        let parseError = ParseError(code: .internalServer, message: "Object not found")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(parseError)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        self.verificationEmailAsyncError(parseError: parseError, callbackQueue: .main)
    }

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

    func testDeleteCommand() {
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId
        do {
            let command = try user.deleteCommand()
            XCTAssertNotNil(command)
            XCTAssertEqual(command.path.urlComponent, "/users/\(objectId)")
            XCTAssertEqual(command.method, API.Method.DELETE)
            XCTAssertNil(command.body)
        } catch {
            XCTFail(error.localizedDescription)
        }

        let user2 = User()
        XCTAssertThrowsError(try user2.deleteCommand())
    }

    func testDeleteCurrent() async throws {
        try await testLogin()
        let user = try await User.current()

        do {
            try await user.delete(options: [])
            do {
                _ = try await User.current()
                XCTFail("Should have thrown error")
            } catch {
                XCTAssertTrue(error.containedIn([.otherCause]))
            }
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            try await user.delete(options: [.usePrimaryKey])
            do {
                _ = try await User.current()
                XCTFail("Should have thrown error")
            } catch {
                XCTAssertTrue(error.containedIn([.otherCause]))
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDeleteCurrentAsyncMainQueue() async throws {
        try await testLogin()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Delete installation1")
        let user = try await User.current()

        var userOnServer = user
        userOnServer.updatedAt = user.updatedAt?.addingTimeInterval(+300)

        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder().encode(userOnServer, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            expectation1.fulfill()
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        user.delete { result in
            if case let .failure(error) = result {
                XCTFail(error.localizedDescription)
            }
            Task {
                do {
                    _ = try await User.current()
                    XCTFail("Should have thrown error")
                } catch {
                    XCTAssertTrue(error.containedIn([.otherCause]))
                }
                expectation1.fulfill()
            }
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    // swiftlint:disable:next function_body_length
    func testFetchAll() async throws {
        try await testLogin()
        MockURLProtocol.removeAll()
        let expectation1 = XCTestExpectation(description: "Fetch")

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
            expectation1.fulfill()
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let fetched = try await [user].fetchAll()
        for item in fetched {
            switch item {
            case .success(let fetched):
                XCTAssert(fetched.hasSameObjectId(as: user))
                guard let fetchedCreatedAt = fetched.createdAt,
                    let fetchedUpdatedAt = fetched.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                }
                guard let originalCreatedAt = user.createdAt,
                    let originalUpdatedAt = user.updatedAt,
                    let serverUpdatedAt = user.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                }
                XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
                XCTAssertEqual(fetchedUpdatedAt, serverUpdatedAt)
                let currentUser = try await User.current()
                XCTAssertEqual(currentUser.customKey, user.customKey)

                // Should be updated in memory
                guard let updatedCurrentDate = currentUser.updatedAt else {
                    XCTFail("Should unwrap current date")
                    expectation1.fulfill()
                    return
                }
                XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)

                #if !os(Linux) && !os(Android) && !os(Windows)
                // Should be updated in Keychain
                guard let keychainUser: CurrentUserContainer<BaseParseUser>
                    = try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser),
                    let keychainUpdatedCurrentDate = keychainUser.currentUser?.updatedAt else {
                        XCTFail("Should get object from Keychain")
                        expectation1.fulfill()
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
    func testFetchAllAsyncMainQueueCurrent() async throws {
        try await testLogin()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Fetch user1")
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
            expectation1.fulfill()
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        [user].fetchAll { results in
            switch results {

            case .success(let fetched):
                for fetchedItem in fetched {
                    switch fetchedItem {
                    case .success(let fetched):
                        XCTAssert(fetched.hasSameObjectId(as: user))
                        guard let fetchedCreatedAt = fetched.createdAt,
                              let fetchedUpdatedAt = fetched.updatedAt else {
                            XCTFail("Should unwrap dates")
                            expectation1.fulfill()
                            return
                        }
                        guard let originalCreatedAt = user.createdAt,
                              let originalUpdatedAt = user.updatedAt,
                              let serverUpdatedAt = user.updatedAt else {
                            XCTFail("Should unwrap dates")
                            expectation1.fulfill()
                            return
                        }
                        XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                        XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
                        XCTAssertEqual(fetchedUpdatedAt, serverUpdatedAt)

                        // Should be updated in memory
                        let immutableOriginalUser = user
                        Task {
                            do {
                                let updatedCurrentUser = try await User.current()
                                XCTAssertEqual(updatedCurrentUser.customKey, immutableOriginalUser.customKey)

                                guard let updatedCurrentDate = updatedCurrentUser.updatedAt else {
                                    XCTFail("Should unwrap current date")
                                    expectation1.fulfill()
                                    return
                                }
                                XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)
                            } catch {
                                XCTFail(error.localizedDescription)
                            }
                            expectation1.fulfill()
                        }
                    case .failure(let error):
                        XCTFail("Should have fetched: \(error.localizedDescription)")
                        expectation1.fulfill()
                    }
                }
            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
            XCTAssertTrue(Thread.isMainThread)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func testSaveAllCurrent() async throws {
        try await testLogin()
        MockURLProtocol.removeAll()

        var user = try await User.current()
        user.createdAt = nil
        var user2 = user
        user2.customKey = "oldValue"
        user.updatedAt = user.updatedAt?.addingTimeInterval(+300)
        user.customKey = "newValue"
        let userOnServer = [BatchResponseItem<User>(success: user, error: nil),
                            BatchResponseItem<User>(success: user2, error: nil)]

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

        do {
            let saved = try await [user].saveAll()
            for savedItem in saved {
                switch savedItem {
                case .success(let saved):
                    XCTAssert(saved.hasSameObjectId(as: user))
                    guard let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                    }
                    guard let originalUpdatedAt = user.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                    }
                    XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                    let updatedCurrentUser = try await User.current()
                    XCTAssertEqual(updatedCurrentUser.customKey, user.customKey)

                    // Should be updated in memory
                    guard let updatedCurrentDate = updatedCurrentUser.updatedAt else {
                        XCTFail("Should unwrap current date")
                        return
                    }
                    XCTAssertEqual(updatedCurrentDate, originalUpdatedAt)

                    #if !os(Linux) && !os(Android) && !os(Windows)
                    // Should be updated in Keychain
                    let keychainUser: CurrentUserContainer<User>?
                        = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser)
                    guard let keychainUpdatedCurrent = keychainUser?.currentUser else {
                        XCTFail("Should get object from Keychain")
                        return
                    }
                    XCTAssertEqual(keychainUpdatedCurrent, saved)
                    #endif
                case .failure(let error):
                    XCTFail("Should have fetched: \(error.localizedDescription)")
                }
            }
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let saved = try await [user].saveAll(transaction: true)
            for savedItem in saved {
                switch savedItem {
                case .success(let saved):
                    XCTAssert(saved.hasSameObjectId(as: user))
                    guard let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                    }
                    guard let originalUpdatedAt = user.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                    }
                    XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)

                    // Should be updated in memory
                    let updatedCurrentUser = try await User.current()
                    XCTAssertEqual(updatedCurrentUser.customKey, user.customKey)

                    guard let updatedCurrentDate = updatedCurrentUser.updatedAt else {
                        XCTFail("Should unwrap current date")
                        return
                    }
                    XCTAssertEqual(updatedCurrentDate, originalUpdatedAt)

                    #if !os(Linux) && !os(Android) && !os(Windows)
                    // Should be updated in Keychain
                    let keychainUser: CurrentUserContainer<User>?
                        = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser)
                    guard let keychainUpdatedCurrent = keychainUser?.currentUser else {
                        XCTFail("Should get object from Keychain")
                        return
                    }
                    XCTAssertEqual(keychainUpdatedCurrent, updatedCurrentUser)
                    #endif
                case .failure(let error):
                    XCTFail("Should have fetched: \(error.localizedDescription)")
                }
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func testSaveAllAsyncMainQueueCurrent() async throws {
        try await testLogin()
        MockURLProtocol.removeAll()

        var user = try await User.current()
        user.createdAt = nil
        var user2 = user
        user2.customKey = "oldValue"
        user.updatedAt = user.updatedAt?.addingTimeInterval(+300)
        user.customKey = "newValue"
        let userOnServer = [BatchResponseItem<User>(success: user, error: nil),
                            BatchResponseItem<User>(success: user2, error: nil)]

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

        let originalUser = user
        let expectation1 = XCTestExpectation(description: "Save user1")
        let expectation2 = XCTestExpectation(description: "Save user2")
        [user].saveAll { results in
            switch results {

            case .success(let saved):
                for savedItem in saved {
                    switch savedItem {
                    case .success(let saved):
                        XCTAssert(saved.hasSameObjectId(as: user))
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
                        XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                        Task {
                            do {
                                let updatedCurrentUser = try await User.current()
                                XCTAssertEqual(updatedCurrentUser.customKey, originalUser.customKey)

                                // Should be updated in memory
                                guard let updatedCurrentDate = updatedCurrentUser.updatedAt else {
                                    XCTFail("Should unwrap current date")
                                    expectation1.fulfill()
                                    return
                                }
                                XCTAssertEqual(updatedCurrentDate, originalUpdatedAt)

                                #if !os(Linux) && !os(Android) && !os(Windows)
                                // Should be updated in Keychain
                                let keychainUser: CurrentUserContainer<User>?
                                    = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser)
                                guard let keychainUpdatedCurrent = keychainUser?.currentUser else {
                                    XCTFail("Should get object from Keychain")
                                    return
                                }
                                XCTAssertEqual(keychainUpdatedCurrent, updatedCurrentUser)
                                #endif
                            } catch {
                                XCTFail(error.localizedDescription)
                            }
                            expectation1.fulfill()
                        }
                    case .failure(let error):
                        XCTFail("Should have fetched: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
            XCTAssertTrue(Thread.isMainThread)
            expectation1.fulfill()
        }

        [user].saveAll(transaction: true) { results in
            switch results {

            case .success(let saved):
                for savedItem in saved {
                    switch savedItem {
                    case .success(let saved):
                        XCTAssert(saved.hasSameObjectId(as: user))
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
                        XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                        Task {
                            do {
                                let updatedCurrentUser = try await User.current()
                                XCTAssertEqual(updatedCurrentUser.customKey, originalUser.customKey)

                                // Should be updated in memory
                                guard let updatedCurrentDate = updatedCurrentUser.updatedAt else {
                                    XCTFail("Should unwrap current date")
                                    expectation2.fulfill()
                                    return
                                }
                                XCTAssertEqual(updatedCurrentDate, originalUpdatedAt)

                                #if !os(Linux) && !os(Android) && !os(Windows)
                                // Should be updated in Keychain
                                let keychainUser: CurrentUserContainer<User>?
                                    = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser)
                                guard let keychainUpdatedCurrent = keychainUser?.currentUser else {
                                    XCTFail("Should get object from Keychain")
                                    return
                                }
                                XCTAssertEqual(keychainUpdatedCurrent, updatedCurrentUser)
                                #endif
                            } catch {
                                XCTFail(error.localizedDescription)
                            }
                            expectation2.fulfill()
                        }

                    case .failure(let error):
                        XCTFail("Should have fetched: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    // swiftlint:disable:next function_body_length
    func testDeleteAllCurrent() async throws {
        try await testLogin()
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

        let expectation1 = XCTestExpectation(description: "Delete user1")
        let expectation2 = XCTestExpectation(description: "Delete user2")
        do {
            let deleted = try await [user].deleteAll()
            deleted.forEach {
                if case let .failure(error) = $0 {
                    XCTFail("Should have deleted: \(error.localizedDescription)")
                }
                Task {
                    do {
                        _ = try await User.current()
                        XCTFail("Should have thrown error")
                    } catch {
                        XCTAssertTrue(error.containedIn([.otherCause]))
                    }
                    expectation1.fulfill()
                }
            }
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let deleted = try await [user].deleteAll(transaction: true)
            deleted.forEach {
                if case let .failure(error) = $0 {
                    XCTFail("Should have deleted: \(error.localizedDescription)")
                }
                Task {
                    do {
                        _ = try await User.current()
                        XCTFail("Should have thrown error")
                    } catch {
                        XCTAssertTrue(error.containedIn([.otherCause]))
                    }
                    expectation2.fulfill()
                }
            }
        } catch {
            XCTFail(error.localizedDescription)
            expectation1.fulfill()
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    // swiftlint:disable:next function_body_length
    func testDeleteAllAsyncMainQueueCurrent() async throws {
        try await testLogin()
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

        let expectation1 = XCTestExpectation(description: "Delete user1")
        let expectation2 = XCTestExpectation(description: "Delete user2")
        [user].deleteAll { results in
            switch results {

            case .success(let deleted):
                XCTAssertTrue(Thread.isMainThread)
                deleted.forEach {
                    if case let .failure(error) = $0 {
                        XCTFail("Should have deleted: \(error.localizedDescription)")
                    }
                    Task {
                        do {
                            _ = try await User.current()
                            XCTFail("Should have thrown error")
                        } catch {
                            XCTAssertTrue(error.containedIn([.otherCause]))
                        }
                        expectation1.fulfill()
                    }
                }
            case .failure(let error):
                XCTFail("Should have deleted: \(error.localizedDescription)")
                XCTAssertTrue(Thread.isMainThread)
                expectation1.fulfill()
            }
        }

        [user].deleteAll(transaction: true) { results in
            switch results {

            case .success(let deleted):
                XCTAssertTrue(Thread.isMainThread)
                deleted.forEach {
                    if case let .failure(error) = $0 {
                        XCTFail("Should have deleted: \(error.localizedDescription)")
                    }
                    Task {
                        do {
                            _ = try await User.current()
                            XCTFail("Should have thrown error")
                        } catch {
                            XCTAssertTrue(error.containedIn([.otherCause]))
                        }
                        expectation2.fulfill()
                    }
                }
            case .failure(let error):
                XCTFail("Should have deleted: \(error.localizedDescription)")
                XCTAssertTrue(Thread.isMainThread)
                expectation2.fulfill()
            }
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testMeCommand() {
        var user = User()
        user.objectId = "me"
        do {
            let command = try user.meCommand(sessionToken: "yolo")
            XCTAssertNotNil(command)
            XCTAssertEqual(command.path.urlComponent, "/users/me")
            XCTAssertEqual(command.method, API.Method.GET)
            XCTAssertNil(command.params)
            XCTAssertNil(command.body)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testBecome() async throws {
        try await testLogin()
        MockURLProtocol.removeAll()

        let user = try await User.current()

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = user.updatedAt?.addingTimeInterval(+300)
        serverResponse.sessionToken = "newValue"
        serverResponse.username = "stop"

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

        do {
            let become = try await user.become(sessionToken: "newValue")
            XCTAssert(become.hasSameObjectId(as: userOnServer))
            guard let becomeUpdatedAt = become.updatedAt else {
                XCTFail("Should unwrap dates")
                return
            }
            guard let originalUpdatedAt = user.updatedAt else {
                XCTFail("Should unwrap dates")
                return
            }
            XCTAssertGreaterThan(becomeUpdatedAt, originalUpdatedAt)
            XCTAssertNil(become.ACL)

            // Should be updated in memory
            let updatedCurrentUser = try await User.current()
            XCTAssertEqual(updatedCurrentUser.updatedAt, becomeUpdatedAt)

            // Should be updated in Keychain
            #if !os(Linux) && !os(Android) && !os(Windows)
            // Should be updated in Keychain
            let keychainUser: CurrentUserContainer<User>?
                = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser)
            guard let keychainUpdatedCurrent = keychainUser?.currentUser else {
                XCTFail("Should get object from Keychain")
                return
            }
            XCTAssertEqual(keychainUpdatedCurrent, become)
            #endif

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testBecomeAsync() async throws { // swiftlint:disable:this function_body_length
        try await testLogin()
        MockURLProtocol.removeAll()

        let user = try await User.current()

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = user.updatedAt?.addingTimeInterval(+300)
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
                guard let becomeUpdatedAt = become.updatedAt else {
                    XCTFail("Should unwrap dates")
                    expectation1.fulfill()
                    return
                }
                guard let originalUpdatedAt = user.updatedAt else {
                    XCTFail("Should unwrap dates")
                    expectation1.fulfill()
                    return
                }
                XCTAssertGreaterThan(becomeUpdatedAt, originalUpdatedAt)
                XCTAssertNil(become.ACL)

                // Should be updated in memory
                Task {
                    do {
                        let updatedCurrentUser = try await User.current()
                        XCTAssertEqual(updatedCurrentUser.updatedAt, becomeUpdatedAt)

                        #if !os(Linux) && !os(Android) && !os(Windows)
                        // Should be updated in Keychain
                        let keychainUser: CurrentUserContainer<User>?
                            = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser)
                        guard let keychainUpdatedCurrent = keychainUser?.currentUser else {
                            XCTFail("Should get object from Keychain")
                            return
                        }
                        XCTAssertEqual(keychainUpdatedCurrent, updatedCurrentUser)
                        #endif
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
// swiftlint:disable:this file_length
