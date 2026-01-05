//
//  ParseInstallationCombineTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/30/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)

import Foundation
import XCTest
import Combine
@testable import ParseSwift

// swiftlint:disable function_body_length line_length
class ParseInstallationCombineTests: XCTestCase, @unchecked Sendable { // swiftlint:disable:this type_body_length

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
    }

    let testInstallationObjectId = "yarr"

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
        try KeychainStore.shared.deleteAll()
        #endif
        try await ParseStorage.shared.deleteAll()
    }

    @MainActor
    func login() async throws {
        let loginResponse = LoginSignupResponse()

        let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
        MockURLProtocol.mockRequests { _ in
			MockURLResponse(data: encoded, statusCode: 200)
        }
        _ = try await User.login(username: loginUserName, password: loginPassword)
    }

    @MainActor
    func saveCurrentInstallation() async throws {
        let installation = try await Installation.current()

        var installationOnServer = installation
        installationOnServer.objectId = testInstallationObjectId
        installationOnServer.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

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

        let saved = try await installation.save()
        let newCurrentInstallation = try await Installation.current()
        XCTAssertTrue(saved.hasSameInstallationId(as: newCurrentInstallation))
        XCTAssertTrue(saved.hasSameObjectId(as: newCurrentInstallation))
        XCTAssertTrue(saved.hasSameObjectId(as: installationOnServer))
        XCTAssertTrue(saved.hasSameInstallationId(as: installationOnServer))
        XCTAssertNil(saved.ACL)
    }

    func testFetch() async throws {
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Update installation1")
        let expectation2 = XCTestExpectation(description: "Update installation2")

        let installation = try await Installation.current()
        guard let savedObjectId = installation.objectId else {
            XCTFail("Should unwrap")
            expectation1.fulfill()
            return
        }
        XCTAssertEqual(savedObjectId, self.testInstallationObjectId)

        var serverResponse = installation
        serverResponse.updatedAt = installation.updatedAt?.addingTimeInterval(+300)
        serverResponse.customKey = "newValue"

		let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
        MockURLProtocol.mockRequests { _ in
			MockURLResponse(data: encoded, statusCode: 200)
        }

        let response = serverResponse
        let publisher = installation.fetchPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    expectation2.fulfill()
                }
                expectation1.fulfill()

        }, receiveValue: { fetched in

            XCTAssert(fetched.hasSameObjectId(as: serverResponse))
            XCTAssert(fetched.hasSameInstallationId(as: serverResponse))
            Task {
                do {
                    let current = try await Installation.current()
                    XCTAssertEqual(current.customKey, response.customKey)
                } catch {
                    XCTFail(error.localizedDescription)
                }
                expectation2.fulfill()
            }
        })
        publisher.store(in: &subscriptions)
        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
    }

    func testSave() async throws {
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Update installation1")
        let expectation2 = XCTestExpectation(description: "Update installation2")

        var installation = try await Installation.current()
        guard let savedObjectId = installation.objectId else {
            XCTFail("Should unwrap")
            expectation1.fulfill()
            return
        }
        installation.customKey = "newValue"
        XCTAssertEqual(savedObjectId, self.testInstallationObjectId)

        var serverResponse = installation
        serverResponse.updatedAt = installation.updatedAt?.addingTimeInterval(+300)

        let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
        MockURLProtocol.mockRequests { _ in
			MockURLResponse(data: encoded, statusCode: 200)
        }

        let response = serverResponse
        let publisher = installation.savePublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    expectation2.fulfill()
                }
                expectation1.fulfill()

        }, receiveValue: { fetched in

            XCTAssert(fetched.hasSameObjectId(as: serverResponse))
            XCTAssert(fetched.hasSameInstallationId(as: serverResponse))
            Task {
                do {
                    let current = try await Installation.current()
                    XCTAssertEqual(current.customKey, response.customKey)
                } catch {
                    XCTFail(error.localizedDescription)
                }
                expectation2.fulfill()
            }
        })
        publisher.store(in: &subscriptions)
        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
    }

    func testCreate() async throws {
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Update installation1")
        var installation = Installation()
        installation.customKey = "newValue"
        installation.installationId = "123"

        var serverResponse = installation
        serverResponse.objectId = "yolo"
        serverResponse.createdAt = Date()

		let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
		// Get dates in correct format from ParseDecoding strategy
		serverResponse = try serverResponse.getDecoder().decode(Installation.self, from: encoded)
        MockURLProtocol.mockRequests { _ in
			MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = installation.createPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { fetched in

            XCTAssert(fetched.hasSameObjectId(as: serverResponse))
            XCTAssert(fetched.hasSameInstallationId(as: serverResponse))
            XCTAssertEqual(fetched.customKey, serverResponse.customKey)
            XCTAssertEqual(fetched.installationId, serverResponse.installationId)
            XCTAssertEqual(fetched.createdAt, serverResponse.createdAt)
            XCTAssertEqual(fetched.updatedAt, serverResponse.createdAt)
        })
        publisher.store(in: &subscriptions)
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testUpdate() async throws {
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Update installation1")
        var installation = Installation()
        installation.customKey = "newValue"
        installation.objectId = "yolo"
        installation.installationId = "123"

        var serverResponse = installation
        serverResponse.updatedAt = Date()

        let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
		// Get dates in correct format from ParseDecoding strategy
		serverResponse = try serverResponse.getDecoder().decode(Installation.self, from: encoded)
        MockURLProtocol.mockRequests { _ in
			MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = installation.updatePublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { fetched in

            XCTAssert(fetched.hasSameObjectId(as: serverResponse))
            XCTAssert(fetched.hasSameInstallationId(as: serverResponse))
            XCTAssertEqual(fetched.customKey, serverResponse.customKey)
            XCTAssertEqual(fetched.installationId, serverResponse.installationId)
            XCTAssertEqual(fetched.updatedAt, serverResponse.updatedAt)
        })
        publisher.store(in: &subscriptions)
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testDelete() async throws {
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Update installation1")
        let expectation2 = XCTestExpectation(description: "Update installation2")
        let installation = try await Installation.current()
        guard let savedObjectId = installation.objectId else {
            XCTFail("Should unwrap")
            return
        }
        XCTAssertEqual(savedObjectId, self.testInstallationObjectId)

        var serverResponse = installation
        serverResponse.updatedAt = installation.updatedAt?.addingTimeInterval(+300)
        serverResponse.customKey = "newValue"

        let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
        MockURLProtocol.mockRequests { _ in
			MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = installation.deletePublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    expectation2.fulfill()
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            Task {
                if let newInstallation = try? await Installation.current() {
                    XCTAssertFalse(installation.hasSameInstallationId(as: newInstallation))
                }
                expectation2.fulfill()
            }
        })
        publisher.store(in: &subscriptions)
        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
    }

    func testFetchAll() async throws {
        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Fetch")
        let expectation2 = XCTestExpectation(description: "Fetch 2")

        var installation = try await Installation.current()

        installation.updatedAt = installation.updatedAt?.addingTimeInterval(+300)
        installation.customKey = "newValue"
        let installationOnServer = QueryResponse<Installation>(results: [installation], count: 1)

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
            // Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(installation)
            installation = try installation.getDecoder().decode(Installation.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            expectation1.fulfill()
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let installationToFetch = installation
        let publisher = [installationToFetch].fetchAllPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    expectation2.fulfill()
                }
                expectation1.fulfill()

        }, receiveValue: { fetched in

            Task {
                do {
                    let current = try await Installation.current()
                    guard let updatedCurrentDate = current.updatedAt else {
                        XCTFail("Should unwrap current date")
                        expectation2.fulfill()
                        return
                    }
                    for object in fetched {
                        switch object {
                        case .success(let fetched):
                            XCTAssert(fetched.hasSameObjectId(as: installationToFetch))
                            guard let fetchedCreatedAt = fetched.createdAt,
                                  let fetchedUpdatedAt = fetched.updatedAt else {
                                XCTFail("Should unwrap dates")
                                expectation2.fulfill()
                                return
                            }
                            guard let originalCreatedAt = installationToFetch.createdAt,
                                  let originalUpdatedAt = installationToFetch.updatedAt,
                                  let serverUpdatedAt = installationToFetch.updatedAt else {
                                XCTFail("Should unwrap dates")
                                expectation2.fulfill()
                                return
                            }
                            XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                            XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
                            XCTAssertEqual(fetchedUpdatedAt, serverUpdatedAt)
                            XCTAssertEqual(current.customKey, installationToFetch.customKey)

                            // Should be updated in memory
                            XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)

                            #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
                            // Should be updated in Keychain
                            guard let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>
                                    = try KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation),
                                  let keychainUpdatedCurrentDate = keychainInstallation.currentInstallation?.updatedAt else {
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
        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
    }

    func testBecome() async throws {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Become Installation")
        let expectation2 = XCTestExpectation(description: "Become Installation 2")

        try await saveCurrentInstallation()
        MockURLProtocol.removeAll()

        let installation = try await Installation.current()
        guard let savedObjectId = installation.objectId else {
            XCTFail("Should unwrap")
            return
        }
        XCTAssertEqual(savedObjectId, self.testInstallationObjectId)

        var installationOnServer = installation
        installationOnServer.createdAt = installation.updatedAt
        installationOnServer.updatedAt = installation.updatedAt?.addingTimeInterval(+300)
        installationOnServer.customKey = "newValue"
        installationOnServer.installationId = "wowsers"
        installationOnServer.channels = ["yo"]
        installationOnServer.deviceToken = "no"

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
            // Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self,
                                                                                from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let response = installationOnServer
        let publisher = Installation.becomePublisher("wowsers")
            .sink(receiveCompletion: { result in
                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                    expectation2.fulfill()
                }
                expectation1.fulfill()

        }, receiveValue: { saved in
            Task {
                do {
                    let currentInstallation = try await Installation.current()
                    XCTAssertTrue(response.hasSameObjectId(as: saved))
                    XCTAssertTrue(response.hasSameInstallationId(as: saved))
                    XCTAssertTrue(response.hasSameObjectId(as: currentInstallation))
                    XCTAssertTrue(response.hasSameInstallationId(as: currentInstallation))
                    guard let savedCreatedAt = saved.createdAt else {
                        XCTFail("Should unwrap dates")
                        expectation2.fulfill()
                        return
                    }
                    guard let originalCreatedAt = response.createdAt else {
                        XCTFail("Should unwrap dates")
                        expectation2.fulfill()
                        return
                    }
                    XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                    XCTAssertEqual(saved.channels, response.channels)
                    XCTAssertEqual(saved.deviceToken, response.deviceToken)

                    // Should be updated in memory
                    XCTAssertEqual(currentInstallation.installationId, "wowsers")
                    XCTAssertEqual(currentInstallation.customKey, response.customKey)
                    XCTAssertEqual(currentInstallation.channels, response.channels)
                    XCTAssertEqual(currentInstallation.deviceToken, response.deviceToken)

                    #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
                    // Should be updated in Keychain
                    guard let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>
                        = try KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
                            XCTFail("Should get object from Keychain")
                        expectation2.fulfill()
                        return
                    }
                    XCTAssertEqual(keychainInstallation.currentInstallation?.installationId, "wowsers")
                    XCTAssertEqual(keychainInstallation.currentInstallation?.channels, response.channels)
                    XCTAssertEqual(keychainInstallation.currentInstallation?.deviceToken, response.deviceToken)
                    #endif
                } catch {
                    XCTFail(error.localizedDescription)
                }
                expectation2.fulfill()
            }
        })
        publisher.store(in: &subscriptions)
        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
    }

    func testBecomeMissingObjectId() async throws {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Become Installation")
        try await ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentInstallation)
        #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        try KeychainStore.shared.delete(valueFor: ParseStorage.Keys.currentInstallation)
        #endif
        await Installation.setCurrent(nil)

        let publisher = Installation.becomePublisher("wowsers")
            .sink(receiveCompletion: { result in
                if case let .failure(error) = result {
                    XCTAssertTrue(error.message.contains("does not exist"))
                } else {
                    XCTFail("Should have error")
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have thrown error")
            expectation1.fulfill()
        })
        publisher.store(in: &subscriptions)
        await fulfillment(of: [expectation1], timeout: 20.0)
    }
}

#endif
