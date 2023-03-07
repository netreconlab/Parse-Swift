//
//  MigrateObjCSDKCombineTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 8/21/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine) && !os(Linux) && !os(Android) && !os(Windows)

import Foundation
import XCTest
import Combine
@testable import ParseSwift

// swiftlint:disable type_body_length function_body_length

class MigrateObjCSDKCombineTests: XCTestCase {
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

    struct Installation: ParseInstallation {
        var installationId: String?
        var deviceType: String?
        var deviceToken: String?
        var badge: Int?
        var timeZone: String?
        var channels: [String]?
        var appName: String?
        var appIdentifier: String?
        var appVersion: String?
        var parseVersion: String?
        var localeIdentifier: String?
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?
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

    let loginUserName = "hello10"
    let loginPassword = "world"
    let objcInstallationId = "helloWorld"
    let objcSessionToken = "wow"
    let objcSessionToken2 = "now"
    let testInstallationObjectId = "yarr"

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
        try await KeychainStore.objectiveC?.deleteAllObjectiveC()
        #endif
        try await ParseStorage.shared.deleteAll()
    }

    func setupObjcKeychainSDK(useOldObjCToken: Bool = false,
                              useBothTokens: Bool = false,
                              installationId: String) async throws {

        // Set keychain the way objc sets keychain
        guard let objcParseKeychain = KeychainStore.objectiveC else {
            XCTFail("Should have unwrapped")
            return
        }

        let currentUserDictionary = ["sessionToken": objcSessionToken]
        let currentUserDictionary2 = ["session_token": objcSessionToken2]
        let currentUserDictionary3 = ["sessionToken": objcSessionToken,
                                      "session_token": objcSessionToken2]
        _ = await objcParseKeychain.setObjectiveC(object: installationId, forKey: "installationId")
        if useBothTokens {
            _ = await objcParseKeychain.setObjectiveC(object: currentUserDictionary3, forKey: "currentUser")
        } else if !useOldObjCToken {
            _ = await objcParseKeychain.setObjectiveC(object: currentUserDictionary, forKey: "currentUser")
        } else {
            _ = await objcParseKeychain.setObjectiveC(object: currentUserDictionary2, forKey: "currentUser")
        }
    }

    func loginNormally(sessionToken: String) async throws -> User {
        var loginResponse = LoginSignupResponse()
        loginResponse.sessionToken = sessionToken

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

    func testLoginUsingObjCKeychain() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Login")
        let expectation2 = XCTestExpectation(description: "Update")

        try await setupObjcKeychainSDK(installationId: objcInstallationId)

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date().addingTimeInterval(+300)
        serverResponse.sessionToken = objcSessionToken
        serverResponse.username = loginUserName

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                serverResponse = try ParseCoding.jsonDecoder().decode(LoginSignupResponse.self, from: encoded)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let publisher = User.loginUsingObjCKeychainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                }
                DispatchQueue.main.async {
                    expectation1.fulfill()
                }

        }, receiveValue: { loggedIn in
            XCTAssertEqual(loggedIn.updatedAt, serverResponse.updatedAt)
            XCTAssertEqual(loggedIn.email, serverResponse.email)
            XCTAssertEqual(loggedIn.username, self.loginUserName)
            XCTAssertNil(loggedIn.password)
            XCTAssertEqual(loggedIn.objectId, serverResponse.objectId)

            XCTAssertEqual(loggedIn.customKey, serverResponse.customKey)
            XCTAssertNil(loggedIn.ACL)

            Task {
                do {
                    var sessionToken = try await User.sessionToken()
                    XCTAssertEqual(sessionToken, self.objcSessionToken)
                    let userFromKeychain = try await User.current()
                    XCTAssertEqual(loggedIn.updatedAt, userFromKeychain.updatedAt)
                    XCTAssertEqual(loggedIn.email, userFromKeychain.email)
                    XCTAssertEqual(userFromKeychain.username, self.loginUserName)
                    XCTAssertNil(userFromKeychain.password)
                    XCTAssertEqual(loggedIn.objectId, userFromKeychain.objectId)
                    sessionToken = try await User.sessionToken()
                    XCTAssertEqual(sessionToken, self.objcSessionToken)
                    XCTAssertEqual(loggedIn.customKey, userFromKeychain.customKey)
                    XCTAssertNil(userFromKeychain.ACL)
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

    func testLoginUsingObjCKeychainOldSessionTokenKey() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Login")
        let expectation2 = XCTestExpectation(description: "Update")

        try await setupObjcKeychainSDK(useOldObjCToken: true,
                                       installationId: objcInstallationId)

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date().addingTimeInterval(+300)
        serverResponse.sessionToken = objcSessionToken2
        serverResponse.username = loginUserName

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                serverResponse = try ParseCoding.jsonDecoder().decode(LoginSignupResponse.self, from: encoded)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let publisher = User.loginUsingObjCKeychainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                }
                DispatchQueue.main.async {
                    expectation1.fulfill()
                }

        }, receiveValue: { loggedIn in
            XCTAssertEqual(loggedIn.updatedAt, serverResponse.updatedAt)
            XCTAssertEqual(loggedIn.email, serverResponse.email)
            XCTAssertEqual(loggedIn.username, self.loginUserName)
            XCTAssertNil(loggedIn.password)
            XCTAssertEqual(loggedIn.objectId, serverResponse.objectId)
            XCTAssertEqual(loggedIn.customKey, serverResponse.customKey)
            XCTAssertNil(loggedIn.ACL)

            Task {
                do {
                    var sessionToken = try await User.sessionToken()
                    XCTAssertEqual(sessionToken, self.objcSessionToken2)
                    let userFromKeychain = try await User.current()
                    XCTAssertEqual(loggedIn.updatedAt, userFromKeychain.updatedAt)
                    XCTAssertEqual(loggedIn.email, userFromKeychain.email)
                    XCTAssertEqual(userFromKeychain.username, self.loginUserName)
                    XCTAssertNil(userFromKeychain.password)
                    XCTAssertEqual(loggedIn.objectId, userFromKeychain.objectId)
                    sessionToken = try await User.sessionToken()
                    XCTAssertEqual(sessionToken, self.objcSessionToken2)
                    XCTAssertEqual(loggedIn.customKey, userFromKeychain.customKey)
                    XCTAssertNil(userFromKeychain.ACL)
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

    func testLoginUsingObjCKeychainUseNewOverOld() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Login")
        let expectation2 = XCTestExpectation(description: "Update")

        try await setupObjcKeychainSDK(useBothTokens: true,
                                       installationId: objcInstallationId)

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date().addingTimeInterval(+300)
        serverResponse.sessionToken = objcSessionToken
        serverResponse.username = loginUserName

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                serverResponse = try ParseCoding.jsonDecoder().decode(LoginSignupResponse.self, from: encoded)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let publisher = User.loginUsingObjCKeychainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                }
                DispatchQueue.main.async {
                    expectation1.fulfill()
                }

        }, receiveValue: { loggedIn in
            XCTAssertEqual(loggedIn.updatedAt, serverResponse.updatedAt)
            XCTAssertEqual(loggedIn.email, serverResponse.email)
            XCTAssertEqual(loggedIn.username, self.loginUserName)
            XCTAssertNil(loggedIn.password)
            XCTAssertEqual(loggedIn.objectId, serverResponse.objectId)
            XCTAssertEqual(loggedIn.customKey, serverResponse.customKey)
            XCTAssertNil(loggedIn.ACL)

            Task {
                do {
                    var sessionToken = try await User.sessionToken()
                    XCTAssertEqual(sessionToken, self.objcSessionToken)
                    let userFromKeychain = try await User.current()
                    XCTAssertEqual(loggedIn.updatedAt, userFromKeychain.updatedAt)
                    XCTAssertEqual(loggedIn.email, userFromKeychain.email)
                    XCTAssertEqual(userFromKeychain.username, self.loginUserName)
                    XCTAssertNil(userFromKeychain.password)
                    XCTAssertEqual(loggedIn.objectId, userFromKeychain.objectId)
                    sessionToken = try await User.sessionToken()
                    XCTAssertEqual(sessionToken, self.objcSessionToken)
                    XCTAssertEqual(loggedIn.customKey, userFromKeychain.customKey)
                    XCTAssertNil(userFromKeychain.ACL)
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

    func testLoginUsingObjCKeychainNoKeychain() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Login")

        let publisher = User.loginUsingObjCKeychainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTAssertTrue(error.message.contains("Objective-C"))
                } else {
                    XCTFail("Should have thrown error")
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have thrown error")
            expectation1.fulfill()
        })
        publisher.store(in: &current)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLoginUsingObjCKeychainAlreadyLoggedIn() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Login")
        let expectation2 = XCTestExpectation(description: "Update")

        try await setupObjcKeychainSDK(installationId: objcInstallationId)
        let currentUser = try await loginNormally(sessionToken: objcSessionToken)
        MockURLProtocol.removeAll()

        let publisher = User.loginUsingObjCKeychainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                }
                DispatchQueue.main.async {
                    expectation1.fulfill()
                }

        }, receiveValue: { returnedUser in
            XCTAssertTrue(currentUser.hasSameObjectId(as: returnedUser))
            expectation2.fulfill()
        })
        publisher.store(in: &current)
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testLoginUsingObjCKeychainAlreadyLoggedInWithDiffererentSession() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Login")

        try await setupObjcKeychainSDK(installationId: objcInstallationId)
        _ = try await loginNormally(sessionToken: objcSessionToken2)
        MockURLProtocol.removeAll()

        let publisher = User.loginUsingObjCKeychainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTAssertTrue(error.message.contains("different"))
                } else {
                    XCTFail("Should have thrown error")
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have thrown error")
            expectation1.fulfill()
        })
        publisher.store(in: &current)
        wait(for: [expectation1], timeout: 20.0)
    }

    func saveCurrentInstallation() async throws {
        let currentInstallation = try await Installation.current()
        var installation = currentInstallation
        installation.objectId = testInstallationObjectId
        installation.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.ACL = nil

        var installationOnServer = installation

        let encoded: Data!
        do {
            encoded = try installationOnServer.getEncoder().encode(installationOnServer, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        do {
            let saved = try await currentInstallation.save()
            let newCurrentInstallation = try await Installation.current()
            XCTAssertTrue(saved.hasSameInstallationId(as: newCurrentInstallation))
            XCTAssertTrue(saved.hasSameObjectId(as: newCurrentInstallation))
            XCTAssertTrue(saved.hasSameObjectId(as: installationOnServer))
            XCTAssertTrue(saved.hasSameInstallationId(as: installationOnServer))
            XCTAssertNil(saved.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDeleteObjCKeychain() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Delete ObjC Installation")
        let expectation2 = XCTestExpectation(description: "Update")

        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        let installation = try await Installation.current()
        guard let savedObjectId = installation.objectId,
              let savedInstallationId = installation.installationId else {
                XCTFail("Should unwrap")
                return
        }
        XCTAssertEqual(savedObjectId, self.testInstallationObjectId)

        try await setupObjcKeychainSDK(installationId: objcInstallationId)

        var installationOnServer = installation
        installationOnServer.updatedAt = installation.updatedAt?.addingTimeInterval(+300)
        installationOnServer.customKey = "newValue"
        installationOnServer.installationId = objcInstallationId
        installationOnServer.channels = ["yo"]
        installationOnServer.deviceToken = "no"

        let encoded: Data!
        do {
            encoded = try installationOnServer.getEncoder().encode(installationOnServer, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = Installation.deleteObjCKeychainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            Task {
                do {
                    // Should be updated in memory
                    let updatedInstallation = try await Installation.current()
                    XCTAssertEqual(updatedInstallation.installationId, savedInstallationId)
                    XCTAssertEqual(updatedInstallation.customKey, installation.customKey)

                    // Should be updated in Keychain
                    let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>?
                    = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation)
                    XCTAssertEqual(keychainInstallation?.currentInstallation?.installationId, savedInstallationId)
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

    func testDeleteObjCKeychainAlreadyMigrated() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Delete ObjC Installation")
        let expectation2 = XCTestExpectation(description: "Update")

        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        let installation = try await Installation.current()
        guard let savedObjectId = installation.objectId,
              let savedInstallationId = installation.installationId else {
                XCTFail("Should unwrap")
                return
        }
        XCTAssertEqual(savedObjectId, self.testInstallationObjectId)

        try await setupObjcKeychainSDK(installationId: savedInstallationId)

        let publisher = Installation.deleteObjCKeychainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            // Should be updated in memory
            Task {
                do {
                    let currentInstallation = try await Installation.current()
                    XCTAssertEqual(currentInstallation.installationId, savedInstallationId)
                    XCTAssertEqual(currentInstallation.customKey, installation.customKey)

                    // Should be updated in Keychain
                    let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>?
                    = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation)
                    XCTAssertEqual(keychainInstallation?.currentInstallation?.installationId, savedInstallationId)
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

    func testDeleteObjCKeychainNoObjcKeychain() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Delete ObjC Installation")

        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        let installation = try await Installation.current()
        guard let savedObjectId = installation.objectId else {
            XCTFail("Should unwrap")
            return
        }
        XCTAssertEqual(savedObjectId, self.testInstallationObjectId)

        let publisher = Installation.deleteObjCKeychainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTAssertTrue(error.message.contains("find Installation"))
                } else {
                    XCTFail("Should have thrown error")
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have thrown error")
            expectation1.fulfill()
        })
        publisher.store(in: &current)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testDeleteObjCKeychainNoCurrentInstallation() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Delete ObjC Installation")

        try await setupObjcKeychainSDK(installationId: objcInstallationId)

        try await ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentInstallation)
        try await KeychainStore.shared.delete(valueFor: ParseStorage.Keys.currentInstallation)
        await Installation.setCurrent(nil)

        let publisher = Installation.deleteObjCKeychainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTAssertTrue(error.message.contains("Current installation"))
                } else {
                    XCTFail("Should have thrown error")
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have thrown error")
            expectation1.fulfill()
        })
        publisher.store(in: &current)
        wait(for: [expectation1], timeout: 20.0)
    }
}
#endif
