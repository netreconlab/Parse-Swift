//
//  ParseHookFunctionCombineTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/20/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)

import Foundation
import XCTest
import Combine
@testable import ParseSwift

class ParseHookFunctionCombineTests: XCTestCase {
    struct TestFunction: ParseHookFunctionable {
        var functionName: String?
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

    func testCreate() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Create hook")

        let hookFunction = TestFunction(name: "foo",
                                        url: URL(string: "https://api.example.com/foo"))

        let server = hookFunction
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = hookFunction.createPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { created in
            XCTAssertEqual(created, server)
        })
        publisher.store(in: &current)
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testCreateError() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Create hook")

        let hookFunction = TestFunction(name: "foo",
                                        url: URL(string: "https://api.example.com/foo"))

        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = hookFunction.createPublisher()
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
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testUpdate() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Update hook")

        let hookFunction = TestFunction(name: "foo",
                                        url: URL(string: "https://api.example.com/foo"))

        let server = hookFunction
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = hookFunction.updatePublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { updated in
            XCTAssertEqual(updated, server)
        })
        publisher.store(in: &current)
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testUpdateError() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Update hook")

        let hookFunction = TestFunction(name: "foo",
                                        url: URL(string: "https://api.example.com/foo"))

        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = hookFunction.updatePublisher()
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
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testFetch() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Fetch hook")

        let hookFunction = TestFunction(name: "foo",
                                        url: URL(string: "https://api.example.com/foo"))

        let server = hookFunction
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = hookFunction.fetchPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { fetched in
            XCTAssertEqual(fetched, server)
        })
        publisher.store(in: &current)
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testFetchError() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Fetch hook")

        let hookFunction = TestFunction(name: "foo",
                                        url: URL(string: "https://api.example.com/foo"))

        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = hookFunction.fetchPublisher()
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
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testFetchAll() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "FetchAll hook")

        let hookFunction = TestFunction(name: "foo",
                                        url: URL(string: "https://api.example.com/foo"))

        let server = [hookFunction]
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = hookFunction.fetchAllPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { fetched in
            XCTAssertEqual(fetched, server)
        })
        publisher.store(in: &current)
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testFetchAllError() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "FetchAll hook")

        let hookFunction = TestFunction(name: "foo",
                                        url: URL(string: "https://api.example.com/foo"))

        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = hookFunction.fetchAllPublisher()
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
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testDelete() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Delete hook")

        let hookFunction = TestFunction(name: "foo",
                                        url: URL(string: "https://api.example.com/foo"))

        let server = hookFunction
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = hookFunction.deletePublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { _ in })
        publisher.store(in: &current)
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testDeleteError() async throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Delete hook")

        let hookFunction = TestFunction(name: "foo",
                                        url: URL(string: "https://api.example.com/foo"))

        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = hookFunction.deletePublisher()
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
        await fulfillment(of: [expectation1], timeout: 20.0)
    }
}
#endif
