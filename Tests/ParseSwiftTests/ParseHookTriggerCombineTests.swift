//
//  ParseHookTriggerCombineTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/20/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if canImport(Combine)

import Foundation
import XCTest
import Combine
@testable import ParseSwift

// swiftlint:disable type_body_length

class ParseHookTriggerCombineTests: XCTestCase {
    struct TestTrigger: ParseHookTriggerable {
        var className: String?
        var triggerName: ParseHookTriggerType?
        var url: URL?
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

    func testCreate() throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Create hook")

        let hookTrigger = TestTrigger(className: "foo",
                                      triggerName: .afterSave,
                                      url: URL(string: "https://api.example.com/foo"))

        let server = hookTrigger
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = hookTrigger.createPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { created in
            XCTAssertEqual(created, server)
        })
        publisher.store(in: &current)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testCreateError() throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Create hook")

        let hookTrigger = TestTrigger(className: "foo",
                                      triggerName: .afterSave,
                                      url: URL(string: "https://api.example.com/foo"))

        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = hookTrigger.createPublisher()
            .sink(receiveCompletion: { result in

                if case .finished = result {
                    XCTFail("Should have thrown ParseError")
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have thrown ParseError")
            expectation1.fulfill()
        })
        publisher.store(in: &current)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testUpdate() throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Update hook")

        let hookTrigger = TestTrigger(className: "foo",
                                      triggerName: .afterSave,
                                      url: URL(string: "https://api.example.com/foo"))

        let server = hookTrigger
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = hookTrigger.updatePublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { updated in
            XCTAssertEqual(updated, server)
        })
        publisher.store(in: &current)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testUpdateError() throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Update hook")

        let hookTrigger = TestTrigger(className: "foo",
                                      triggerName: .afterSave,
                                      url: URL(string: "https://api.example.com/foo"))

        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = hookTrigger.updatePublisher()
            .sink(receiveCompletion: { result in

                if case .finished = result {
                    XCTFail("Should have thrown ParseError")
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have thrown ParseError")
            expectation1.fulfill()
        })
        publisher.store(in: &current)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testFetch() throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Fetch hook")

        let hookTrigger = TestTrigger(className: "foo",
                                      triggerName: .afterSave,
                                      url: URL(string: "https://api.example.com/foo"))

        let server = hookTrigger
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = hookTrigger.fetchPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { fetched in
            XCTAssertEqual(fetched, server)
        })
        publisher.store(in: &current)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testFetchError() throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Fetch hook")

        let hookTrigger = TestTrigger(className: "foo",
                                      triggerName: .afterSave,
                                      url: URL(string: "https://api.example.com/foo"))

        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = hookTrigger.fetchPublisher()
            .sink(receiveCompletion: { result in

                if case .finished = result {
                    XCTFail("Should have thrown ParseError")
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have thrown ParseError")
            expectation1.fulfill()
        })
        publisher.store(in: &current)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testFetchAll() throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "FetchAll hook")

        let hookTrigger = TestTrigger(className: "foo",
                                      triggerName: .afterSave,
                                      url: URL(string: "https://api.example.com/foo"))

        let server = [hookTrigger]
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = hookTrigger.fetchAllPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { fetched in
            XCTAssertEqual(fetched, server)
        })
        publisher.store(in: &current)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testFetchAllError() throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "FetchAll hook")

        let hookTrigger = TestTrigger(className: "foo",
                                      triggerName: .afterSave,
                                      url: URL(string: "https://api.example.com/foo"))

        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = hookTrigger.fetchAllPublisher()
            .sink(receiveCompletion: { result in

                if case .finished = result {
                    XCTFail("Should have thrown ParseError")
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have thrown ParseError")
            expectation1.fulfill()
        })
        publisher.store(in: &current)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testDelete() throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Delete hook")

        let hookTrigger = TestTrigger(className: "foo",
                                      triggerName: .afterSave,
                                      url: URL(string: "https://api.example.com/foo"))

        let server = hookTrigger
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = hookTrigger.deletePublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { _ in })
        publisher.store(in: &current)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testDeleteError() throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Delete hook")

        let hookTrigger = TestTrigger(className: "foo",
                                      triggerName: .afterSave,
                                      url: URL(string: "https://api.example.com/foo"))

        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = hookTrigger.deletePublisher()
            .sink(receiveCompletion: { result in

                if case .finished = result {
                    XCTFail("Should have thrown ParseError")
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have thrown ParseError")
            expectation1.fulfill()
        })
        publisher.store(in: &current)
        wait(for: [expectation1], timeout: 20.0)
    }
}
#endif
