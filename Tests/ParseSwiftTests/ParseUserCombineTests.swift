//
//  ParseUserCombineTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/29/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine) && compiler(<6.0.0)

import Foundation
import XCTest
import Combine
@testable import ParseSwift

// swiftlint:disable function_body_length

class ParseUserCombineTests: XCTestCase { // swiftlint:disable:this type_body_length

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
        #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        try await KeychainStore.shared.deleteAll()
        #endif
        try await ParseStorage.shared.deleteAll()
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

    func testSignup() async throws {
        let loginResponse = LoginSignupResponse()
        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Signup user1")
        let expectation2 = XCTestExpectation(description: "Signup user2")
        let publisher = User.signupPublisher(username: loginUserName, password: loginUserName)
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    expectation2.fulfill()
                }
                expectation1.fulfill()

        }, receiveValue: { signedUp in
            XCTAssertNotNil(signedUp)
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
                    let userFromStorage = try await BaseParseUser.current()
                    XCTAssertNotNil(userFromStorage.createdAt)
                    XCTAssertNotNil(userFromStorage.updatedAt)
                    XCTAssertNotNil(userFromStorage.email)
                    XCTAssertNotNil(userFromStorage.username)
                    XCTAssertNil(userFromStorage.password)
                    XCTAssertNotNil(userFromStorage.objectId)
                    XCTAssertNil(userFromStorage.ACL)
                } catch {
                    XCTFail(error.localizedDescription)
                }
                DispatchQueue.main.async {
                    expectation2.fulfill()
                }
            }
        })
        publisher.store(in: &subscriptions)
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1, expectation2], timeout: 20.0)
        #endif
    }

    func testSignupInstance() async throws {
        let loginResponse = LoginSignupResponse()
        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Signup user1")
        let expectation2 = XCTestExpectation(description: "Signup user2")
        var user = User()
        user.username = loginUserName
        user.password = loginPassword
        user.email = "parse@parse.com"
        user.customKey = "blah"
        let publisher = user.signupPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    expectation2.fulfill()
                }
                expectation1.fulfill()

        }, receiveValue: { signedUp in
            XCTAssertNotNil(signedUp)
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
                    let userFromStorage = try await BaseParseUser.current()
                    XCTAssertNotNil(userFromStorage.createdAt)
                    XCTAssertNotNil(userFromStorage.updatedAt)
                    XCTAssertNotNil(userFromStorage.email)
                    XCTAssertNotNil(userFromStorage.username)
                    XCTAssertNil(userFromStorage.password)
                    XCTAssertNotNil(userFromStorage.objectId)
                    XCTAssertNil(userFromStorage.ACL)
                } catch {
                    XCTFail(error.localizedDescription)
                }
                DispatchQueue.main.async {
                    expectation2.fulfill()
                }
            }
        })
        publisher.store(in: &subscriptions)
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1, expectation2], timeout: 20.0)
        #endif
    }

    func testLogin() async throws {
        let loginResponse = LoginSignupResponse()
        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Login user1")
        let expectation2 = XCTestExpectation(description: "Login user2")
        let publisher = User.loginPublisher(username: loginUserName, password: loginUserName)
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    expectation2.fulfill()
                }
                expectation1.fulfill()

        }, receiveValue: { signedUp in
            XCTAssertNotNil(signedUp)
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
                    let userFromStorage = try await BaseParseUser.current()
                    XCTAssertNotNil(userFromStorage.createdAt)
                    XCTAssertNotNil(userFromStorage.updatedAt)
                    XCTAssertNotNil(userFromStorage.email)
                    XCTAssertNotNil(userFromStorage.username)
                    XCTAssertNil(userFromStorage.password)
                    XCTAssertNotNil(userFromStorage.objectId)
                    XCTAssertNil(userFromStorage.ACL)
                } catch {
                    XCTFail(error.localizedDescription)
                }
                DispatchQueue.main.async {
                    expectation2.fulfill()
                }
            }
        })
        publisher.store(in: &subscriptions)
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1, expectation2], timeout: 20.0)
        #endif
    }

    func testBecome() async throws {
        try await login()
        MockURLProtocol.removeAll()

        let user = try await User.current()
        XCTAssertNotNil(user.objectId)

        var serverResponse = LoginSignupResponse()
        serverResponse.createdAt = user.createdAt
        serverResponse.updatedAt = user.updatedAt?.addingTimeInterval(+300)
        serverResponse.sessionToken = "newValue"
        serverResponse.username = "stop"

        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Become user1")
        let expectation2 = XCTestExpectation(description: "Become user2")
        let publisher = user.becomePublisher(sessionToken: serverResponse.sessionToken)
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    expectation2.fulfill()
                }
                expectation1.fulfill()

        }, receiveValue: { signedUp in
            XCTAssertNotNil(signedUp)
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
                    let userFromStorage = try await BaseParseUser.current()
                    XCTAssertNotNil(userFromStorage.createdAt)
                    XCTAssertNotNil(userFromStorage.updatedAt)
                    XCTAssertNotNil(userFromStorage.email)
                    XCTAssertNotNil(userFromStorage.username)
                    XCTAssertNil(userFromStorage.password)
                    XCTAssertNotNil(userFromStorage.objectId)
                    XCTAssertNil(userFromStorage.ACL)
                } catch {
                    XCTFail(error.localizedDescription)
                }
                DispatchQueue.main.async {
                    expectation2.fulfill()
                }
            }
        })
        publisher.store(in: &subscriptions)
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testBecomeTypeMethod() async throws {

        var serverResponse = LoginSignupResponse()
        serverResponse.createdAt = Date()
        serverResponse.updatedAt = Date()
        serverResponse.sessionToken = "newValue"
        serverResponse.username = "stop"

        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Become user1")
        let expectation2 = XCTestExpectation(description: "Become user2")
        let publisher = User.becomePublisher(sessionToken: serverResponse.sessionToken)
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    expectation2.fulfill()
                }
                expectation1.fulfill()

        }, receiveValue: { signedUp in
            XCTAssertNotNil(signedUp)
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
                    let userFromStorage = try await BaseParseUser.current()
                    XCTAssertNotNil(userFromStorage.createdAt)
                    XCTAssertNotNil(userFromStorage.updatedAt)
                    XCTAssertNotNil(userFromStorage.email)
                    XCTAssertNotNil(userFromStorage.username)
                    XCTAssertNil(userFromStorage.password)
                    XCTAssertNotNil(userFromStorage.objectId)
                    XCTAssertNil(userFromStorage.ACL)
                } catch {
                    XCTFail(error.localizedDescription)
                }
                DispatchQueue.main.async {
                    expectation2.fulfill()
                }
            }
        })
        publisher.store(in: &subscriptions)
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testLoginAs() async throws {

        var serverResponse = LoginSignupResponse()
        serverResponse.createdAt = Date()
        serverResponse.updatedAt = Date()
        serverResponse.sessionToken = "newValue"
        serverResponse.username = "stop"

        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "LoginAs user1")
        let expectation2 = XCTestExpectation(description: "LoginAs user2")
        guard let objectId = serverResponse.objectId else {
            XCTFail("Should have unwrapped")
            return
        }
        let publisher = User.loginAsPublisher(objectId: objectId)
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    expectation2.fulfill()
                }
                expectation1.fulfill()

        }, receiveValue: { loggedIn in
            XCTAssertNotNil(loggedIn)
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
                    let userFromStorage = try await BaseParseUser.current()
                    XCTAssertNotNil(userFromStorage.createdAt)
                    XCTAssertNotNil(userFromStorage.updatedAt)
                    XCTAssertNotNil(userFromStorage.email)
                    XCTAssertNotNil(userFromStorage.username)
                    XCTAssertNil(userFromStorage.password)
                    XCTAssertNotNil(userFromStorage.objectId)
                    XCTAssertNil(userFromStorage.ACL)
                } catch {
                    XCTFail(error.localizedDescription)
                }
                DispatchQueue.main.async {
                    expectation2.fulfill()
                }
            }
        })
        publisher.store(in: &subscriptions)
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testLogout() async throws {
        try await login()
        MockURLProtocol.removeAll()

        let serverResponse = NoBody()

        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Logout user1")
        guard let oldInstallationId = try await BaseParseInstallation.current().installationId else {
            XCTFail("Should have unwrapped")
            expectation1.fulfill()
            return
        }
        let publisher = User.logoutPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                Task {
                    if let userFromStorage = try? await BaseParseUser.current() {
                        XCTFail("\(userFromStorage) was not deleted from Keychain during logout")
                    }
                    if let installationFromMemory: CurrentInstallationContainer<BaseParseInstallation>
                        = try await ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentInstallation) {
                        if installationFromMemory.installationId == oldInstallationId ||
                            installationFromMemory.installationId == nil {
                            XCTFail("\(installationFromMemory) was not deleted and recreated in memory during logout")
                        }
                    } else {
                        XCTFail("Should have a new installation")
                    }

                    #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
                    if let installationFromKeychain: CurrentInstallationContainer<BaseParseInstallation>
                        = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) {
                        if installationFromKeychain.installationId == oldInstallationId ||
                            installationFromKeychain.installationId == nil {
                            XCTFail("\(installationFromKeychain) was not deleted & recreated in Keychain during logout")
                        }
                    } else {
                        XCTFail("Should have a new installation")
                    }
                    #endif
                    expectation1.fulfill()
                }

        }, receiveValue: { _ in })
        publisher.store(in: &subscriptions)
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testLogoutError() async throws {
        try await login()
        MockURLProtocol.removeAll()

        let serverResponse = ParseError(code: .internalServer, message: "Object not found")

        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Logout user1")
        guard let oldInstallationId = try await BaseParseInstallation.current().installationId else {
            XCTFail("Should have unwrapped")
            return
        }
        let publisher = User.logoutPublisher()
            .sink(receiveCompletion: { result in

                if case .finished = result {
                    XCTFail("Should have thrown ParseError")
                }

                Task {
                    if let userFromStorage = try? await BaseParseUser.current() {
                        XCTFail("\(userFromStorage) was not deleted from Keychain during logout")
                    }
                    if let installationFromMemory: CurrentInstallationContainer<BaseParseInstallation>
                        = try await ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentInstallation) {
                        if installationFromMemory.installationId == oldInstallationId ||
                            installationFromMemory.installationId == nil {
                            XCTFail("\(installationFromMemory) was not deleted & recreated in memory during logout")
                        }
                    } else {
                        XCTFail("Should have a new installation")
                    }

                    #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
                    if let installationFromKeychain: CurrentInstallationContainer<BaseParseInstallation>
                        = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) {
                        if installationFromKeychain.installationId == oldInstallationId ||
                            installationFromKeychain.installationId == nil {
                            XCTFail("\(installationFromKeychain) was not deleted & recreated in Keychain during logout")
                        }
                    } else {
                        XCTFail("Should have a new installation")
                    }
                    #endif
                    expectation1.fulfill()
                }
        }, receiveValue: { _ in
            XCTFail("Should have thrown ParseError")
            expectation1.fulfill()
        })
        publisher.store(in: &subscriptions)
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testPasswordReset() async throws {
        let serverResponse = NoBody()

        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Password user1")
        let publisher = User.passwordResetPublisher(email: "hello@parse.org")
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { _ in

        })
        publisher.store(in: &subscriptions)
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testPasswordResetError() async throws {
        let parseError = ParseError(code: .internalServer, message: "Object not found")

        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(parseError)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Password user1")
        let publisher = User.passwordResetPublisher(email: "hello@parse.org")
            .sink(receiveCompletion: { result in

                if case .finished = result {
                    XCTFail("Should have thrown ParseError")
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have thrown ParseError")
        })
        publisher.store(in: &subscriptions)
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testVerifyPassword() async throws {
        let serverResponse = LoginSignupResponse()

        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Verify password user1")
        let expectation2 = XCTestExpectation(description: "Verify password user2")
        let publisher = User.verifyPasswordPublisher(password: "world")
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    expectation2.fulfill()
                }
                expectation1.fulfill()

        }, receiveValue: { currentUser in

            XCTAssertNotNil(currentUser)
            XCTAssertNotNil(currentUser.createdAt)
            XCTAssertNotNil(currentUser.updatedAt)
            XCTAssertNotNil(currentUser.email)
            XCTAssertNotNil(currentUser.username)
            XCTAssertNil(currentUser.password)
            XCTAssertNotNil(currentUser.objectId)
            XCTAssertNotNil(currentUser.customKey)
            XCTAssertNil(currentUser.ACL)
            expectation2.fulfill()
        })
        publisher.store(in: &subscriptions)
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1, expectation2], timeout: 20.0)
        #endif
    }

    func testVerifyPasswordError() async throws {
        let parseError = ParseError(code: .userWithEmailNotFound,
                                    message: "User email is not verified.")

        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(parseError)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Verify password user1")
        let publisher = User.verifyPasswordPublisher(password: "world")
            .sink(receiveCompletion: { result in

                if case .finished = result {
                    XCTFail("Should have thrown ParseError")
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have thrown ParseError")
        })
        publisher.store(in: &subscriptions)
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testVerificationEmail() async throws {
        let serverResponse = NoBody()

        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Verification user1")
        let publisher = User.verificationEmailPublisher(email: "hello@parse.org")
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { _ in

        })
        publisher.store(in: &subscriptions)
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testVerificationEmailError() async throws {
        let parseError = ParseError(code: .internalServer, message: "Object not found")

        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(parseError)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Verification user1")
        let publisher = User.verificationEmailPublisher(email: "hello@parse.org")
            .sink(receiveCompletion: { result in

                if case .failure(let error) = result {
                    XCTAssertEqual(error.message, parseError.message)
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have thrown ParseError")
        })
        publisher.store(in: &subscriptions)
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testFetch() async throws {
        try await login()
        MockURLProtocol.removeAll()

        let user = try await User.current()
        XCTAssertNotNil(user.objectId)

        var serverResponse = LoginSignupResponse()
        serverResponse.createdAt = user.createdAt
        serverResponse.updatedAt = user.updatedAt?.addingTimeInterval(+300)
        serverResponse.sessionToken = "newValue"
        serverResponse.username = "stop"

        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Become user1")
        let expectation2 = XCTestExpectation(description: "Become user2")
        let publisher = user.fetchPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    expectation2.fulfill()
                }
                expectation1.fulfill()

        }, receiveValue: { fetched in

            XCTAssertEqual(fetched.objectId, serverResponse.objectId)
            let response = serverResponse
            Task {
                do {
                    let userFromStorage = try await BaseParseUser.current()
                    XCTAssertEqual(userFromStorage.objectId, response.objectId)
                } catch {
                    XCTFail(error.localizedDescription)
                }
                DispatchQueue.main.async {
                    expectation2.fulfill()
                }
            }
        })
        publisher.store(in: &subscriptions)
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1, expectation2], timeout: 20.0)
        #endif
    }

    func testSave() async throws {
        try await login()
        MockURLProtocol.removeAll()

        let user = try await User.current()
        XCTAssertNotNil(user.objectId)

        var serverResponse = LoginSignupResponse()
        serverResponse.createdAt = user.createdAt
        serverResponse.updatedAt = user.updatedAt?.addingTimeInterval(+300)
        serverResponse.sessionToken = "newValue"
        serverResponse.username = "stop"

        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Become user1")
        let expectation2 = XCTestExpectation(description: "Become user2")
        let publisher = user.savePublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    expectation2.fulfill()
                }
                expectation1.fulfill()

        }, receiveValue: { saved in

            XCTAssertEqual(saved.objectId, serverResponse.objectId)
            let response = serverResponse
            Task {
                do {
                    let userFromStorage = try await BaseParseUser.current()
                    XCTAssertEqual(userFromStorage.objectId, response.objectId)
                } catch {
                    XCTFail(error.localizedDescription)
                }
                DispatchQueue.main.async {
                    expectation2.fulfill()
                }
            }
        })
        publisher.store(in: &subscriptions)
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1, expectation2], timeout: 20.0)
        #endif
    }

    func testCreate() async throws {
        try await login()
        MockURLProtocol.removeAll()

        var user = User()
        user.username = "stop"

        var serverResponse = user
        serverResponse.objectId = "yolo"
        serverResponse.createdAt = Date()

        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                serverResponse = try user.getDecoder().decode(User.self, from: encoded)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Become user1")
        let publisher = user.createPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { saved in

            XCTAssertTrue(saved.hasSameObjectId(as: serverResponse))
            XCTAssertEqual(saved.username, serverResponse.username)
            XCTAssertEqual(saved.createdAt, serverResponse.createdAt)
            XCTAssertEqual(saved.updatedAt, serverResponse.createdAt)
        })
        publisher.store(in: &subscriptions)
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testUpdate() async throws {
        try await login()
        MockURLProtocol.removeAll()

        var user = User()
        user.username = "stop"
        user.objectId = "yolo"

        var serverResponse = user
        serverResponse.updatedAt = Date()

        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                serverResponse = try user.getDecoder().decode(User.self, from: encoded)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Become user1")
        let publisher = user.updatePublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { saved in

            XCTAssertTrue(saved.hasSameObjectId(as: serverResponse))
            XCTAssertEqual(saved.username, serverResponse.username)
            XCTAssertEqual(saved.updatedAt, serverResponse.updatedAt)
        })
        publisher.store(in: &subscriptions)
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testDelete() async throws {
        try await login()
        MockURLProtocol.removeAll()

        let user = try await User.current()

        let serverResponse = NoBody()

        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Become user1")
        let expectation2 = XCTestExpectation(description: "Become user2")
        let publisher = user.deletePublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    expectation2.fulfill()
                }
                expectation1.fulfill()

        }, receiveValue: { _ in

            Task {
                do {
                    _ = try await BaseParseUser.current()
                    XCTFail("Should have failed")
                } catch {
                    guard let parseError = error as? ParseError else {
                        XCTFail("Should have casted to ParseError")
                        return
                    }
                    XCTAssertTrue(parseError.message.contains("no current"))
                }
                DispatchQueue.main.async {
                    expectation2.fulfill()
                }
            }
        })
        publisher.store(in: &subscriptions)
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1, expectation2], timeout: 20.0)
        #endif
    }

    func testFetchAll() async throws {
        try await login()
        MockURLProtocol.removeAll()
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Fetch")
        let expectation2 = XCTestExpectation(description: "Fetch 2")

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

        let publisher = [user].fetchAllPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { fetched in
            let originalUser = user
            Task {
                do {
                    let current = try await User.current()
                    guard let updatedCurrentDate = current.updatedAt else {
                        XCTFail("Should unwrap current date")
                        expectation2.fulfill()
                        return
                    }
                    for object in fetched {
                        switch object {
                        case .success(let fetched):
                            XCTAssert(fetched.hasSameObjectId(as: originalUser))
                            guard let fetchedCreatedAt = fetched.createdAt,
                                  let fetchedUpdatedAt = fetched.updatedAt else {
                                XCTFail("Should unwrap dates")
                                expectation2.fulfill()
                                return
                            }
                            guard let originalCreatedAt = originalUser.createdAt,
                                  let originalUpdatedAt = originalUser.updatedAt,
                                  let serverUpdatedAt = originalUser.updatedAt else {
                                XCTFail("Should unwrap dates")
                                expectation2.fulfill()
                                return
                            }
                            XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                            XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
                            XCTAssertEqual(fetchedUpdatedAt, serverUpdatedAt)
                            XCTAssertEqual(current.customKey, originalUser.customKey)

                            // Should be updated in memory
                            XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)

                            #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
                            // Should be updated in Keychain
                            guard let keychainUser: CurrentUserContainer<BaseParseUser>
                                    = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser),
                                  let keychainUpdatedCurrentDate = keychainUser.currentUser?.updatedAt else {
                                XCTFail("Should get object from Keychain")
                                expectation2.fulfill()
                                return
                            }
                            XCTAssertEqual(keychainUpdatedCurrentDate, serverUpdatedAt)
                            #endif
                        case .failure(let error):
                            XCTFail("Should have fetched: \(error.localizedDescription)")
                        }
                    }
                } catch {
                    XCTFail(error.localizedDescription)
                }
                expectation2.fulfill()
            }
        })
        publisher.store(in: &subscriptions)

        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1, expectation2], timeout: 20.0)
        #endif
    }

    func testSaveAll() async throws {
        try await login()
        MockURLProtocol.removeAll()
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")
        let expectation2 = XCTestExpectation(description: "Save 2")

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
            expectation1.fulfill()
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = [user].saveAllPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    expectation2.fulfill()
                }
                expectation1.fulfill()

        }, receiveValue: { saved in

            let original = user
            Task {
                do {
                    let current = try await User.current()
                    guard let updatedCurrentDate = current.updatedAt else {
                        XCTFail("Should unwrap current date")
                        expectation2.fulfill()
                        return
                    }
                    for object in saved {
                        switch object {
                        case .success(let saved):
                            XCTAssert(saved.hasSameObjectId(as: original))
                            guard let savedUpdatedAt = saved.updatedAt else {
                                XCTFail("Should unwrap dates")
                                expectation2.fulfill()
                                return
                            }
                            guard let originalUpdatedAt = original.updatedAt else {
                                XCTFail("Should unwrap dates")
                                expectation2.fulfill()
                                return
                            }
                            XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                            XCTAssertEqual(current.customKey, original.customKey)

                            // Should be updated in memory
                            XCTAssertEqual(updatedCurrentDate, originalUpdatedAt)

                            #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
                            // Should be updated in Keychain
                            guard let keychainUser: CurrentUserContainer<BaseParseUser>
                                    = try await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser),
                                  let keychainUpdatedCurrentDate = keychainUser.currentUser?.updatedAt else {
                                XCTFail("Should get object from Keychain")
                                expectation2.fulfill()
                                return
                            }
                            XCTAssertEqual(keychainUpdatedCurrentDate, originalUpdatedAt)
                            #endif
                        case .failure(let error):
                            XCTFail("Should have fetched: \(error.localizedDescription)")
                        }
                    }
                } catch {
                    XCTFail(error.localizedDescription)
                }
                expectation2.fulfill()
            }
        })
        publisher.store(in: &subscriptions)

        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1, expectation2], timeout: 20.0)
        #endif
    }

    func testCreateAll() async throws {
        try await login()
        MockURLProtocol.removeAll()
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        var user = User()
        user.username = "stop"

        var serverResponse = user
        serverResponse.objectId = "yolo"
        serverResponse.createdAt = Date()
        let userOnServer = [BatchResponseItem<User>(success: serverResponse, error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
            // Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(serverResponse)
            serverResponse = try user.getDecoder().decode(User.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            expectation1.fulfill()
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = [user].createAllPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { saved in

            saved.forEach {
                switch $0 {
                case .success(let saved):
                    XCTAssertTrue(saved.hasSameObjectId(as: serverResponse))
                    guard let savedCreatedAt = saved.createdAt,
                        let savedUpdatedAt = saved.updatedAt else {
                            XCTFail("Should unwrap dates")
                            expectation1.fulfill()
                            return
                    }
                    guard let originalCreatedAt = serverResponse.createdAt else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                    }
                    XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                    XCTAssertEqual(savedUpdatedAt, originalCreatedAt)

                case .failure(let error):
                    XCTFail("Should have fetched: \(error.localizedDescription)")
                }
            }
        })
        publisher.store(in: &subscriptions)

        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testReplaceAllCreate() async throws {
        try await login()
        MockURLProtocol.removeAll()
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        var user = User()
        user.username = "stop"
        user.objectId = "yolo"

        var serverResponse = user
        serverResponse.createdAt = Date()
        let userOnServer = [BatchResponseItem<User>(success: serverResponse, error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
            // Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(serverResponse)
            serverResponse = try user.getDecoder().decode(User.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            expectation1.fulfill()
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = [user].replaceAllPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { saved in

            saved.forEach {
                switch $0 {
                case .success(let saved):
                    XCTAssertTrue(saved.hasSameObjectId(as: serverResponse))
                    XCTAssertEqual(saved.createdAt, serverResponse.createdAt)
                    XCTAssertEqual(saved.updatedAt, serverResponse.createdAt)

                case .failure(let error):
                    XCTFail("Should have fetched: \(error.localizedDescription)")
                }
            }
        })
        publisher.store(in: &subscriptions)

        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testReplaceAllUpdate() async throws {
        try await login()
        MockURLProtocol.removeAll()
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        var user = User()
        user.username = "stop"
        user.objectId = "yolo"

        var serverResponse = user
        serverResponse.updatedAt = Date()
        let userOnServer = [BatchResponseItem<User>(success: serverResponse, error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
            // Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(serverResponse)
            serverResponse = try user.getDecoder().decode(User.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            expectation1.fulfill()
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = [user].replaceAllPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { saved in

            saved.forEach {
                switch $0 {
                case .success(let saved):
                    XCTAssertTrue(saved.hasSameObjectId(as: serverResponse))
                    guard let savedUpdatedAt = saved.updatedAt else {
                            XCTFail("Should unwrap dates")
                            expectation1.fulfill()
                            return
                    }
                    guard let originalUpdatedAt = serverResponse.updatedAt else {
                            XCTFail("Should unwrap dates")
                            expectation1.fulfill()
                            return
                    }
                    XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)

                case .failure(let error):
                    XCTFail("Should have fetched: \(error.localizedDescription)")
                }
            }
        })
        publisher.store(in: &subscriptions)

        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testUpdateAll() async throws {
        try await login()
        MockURLProtocol.removeAll()
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        var user = User()
        user.username = "stop"
        user.objectId = "yolo"

        var serverResponse = user
        serverResponse.updatedAt = Date()
        let userOnServer = [BatchResponseItem<User>(success: serverResponse, error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
            // Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(serverResponse)
            serverResponse = try user.getDecoder().decode(User.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            expectation1.fulfill()
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = [user].updateAllPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { saved in

            saved.forEach {
                switch $0 {
                case .success(let saved):
                    XCTAssertTrue(saved.hasSameObjectId(as: serverResponse))
                    guard let savedUpdatedAt = saved.updatedAt else {
                            XCTFail("Should unwrap dates")
                            expectation1.fulfill()
                            return
                    }
                    guard let originalUpdatedAt = serverResponse.updatedAt else {
                            XCTFail("Should unwrap dates")
                            expectation1.fulfill()
                            return
                    }
                    XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)

                case .failure(let error):
                    XCTFail("Should have fetched: \(error.localizedDescription)")
                }
            }
        })
        publisher.store(in: &subscriptions)

        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testDeleteAll() async throws {
        try await login()
        MockURLProtocol.removeAll()
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        let user = try await User.current()

        let userOnServer = [BatchResponseItem<NoBody>(success: NoBody(), error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            expectation1.fulfill()
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = [user].deleteAllPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { deleted in
            deleted.forEach {
                if case let .failure(error) = $0 {
                    XCTFail("Should have deleted: \(error.localizedDescription)")
                }
            }
        })
        publisher.store(in: &subscriptions)

        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }
}

#endif
