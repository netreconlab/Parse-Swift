//
//  ParseQueryCombineTests.swift
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

class ParseQueryCombineTests: XCTestCase { // swiftlint:disable:this type_body_length

    struct GameScore: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        //: Your own properties
        var points: Int?
        var player: String?

        // custom initializers
        init() {}

        init (objectId: String?) {
            self.objectId = objectId
        }
        init(points: Int) {
            self.points = points
            self.player = "Jen"
        }
        init(points: Int, name: String) {
            self.points = points
            self.player = name
        }
    }

    struct AnyResultsResponse<U: Codable>: Codable {
        let results: [U]
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
                                        usingPostForQuery: true,
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

    func testFind() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Find")

        var scoreOnServer = GameScore(points: 10)
        scoreOnServer.points = 11
        scoreOnServer.objectId = "yolo"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let query = GameScore.query

        let publisher = query.findPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { found in

            guard let object = found.first else {
                XCTFail("Should have unwrapped")
                return
            }
            XCTAssert(object.hasSameObjectId(as: scoreOnServer))
        })
        publisher.store(in: &current)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testWithCount() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Find")

        var scoreOnServer = GameScore(points: 10)
        scoreOnServer.points = 11
        scoreOnServer.objectId = "yolo"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let query = GameScore.query

        let publisher = query.withCountPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { found in

            guard let object = found.0.first else {
                XCTFail("Should have unwrapped")
                return
            }
            XCTAssert(object.hasSameObjectId(as: scoreOnServer))
            XCTAssertEqual(found.1, 1)
        })
        publisher.store(in: &current)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testFindAll() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "FindAll")

        var scoreOnServer = GameScore(points: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = AnyResultsResponse(results: [scoreOnServer])
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        let query = GameScore.query
        let publisher = query.findAllPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { found in

            guard let object = found.first else {
                XCTFail("Should have unwrapped")
                return
            }
            XCTAssert(object.hasSameObjectId(as: scoreOnServer))
        })
        publisher.store(in: &current)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testFindExplain() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        let json = AnyResultsResponse(results: [["yolo": "yarr"]])

        let encoded: Data!
        do {
            encoded = try JSONEncoder().encode(json)
        } catch {
            XCTFail("Should encode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let query = GameScore.query

        let publisher = query.findExplainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

            }, receiveValue: { (queryResult: [[String: String]]) in
                XCTAssertEqual(queryResult, json.results)
        })
        publisher.store(in: &current)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testWithCountExplain() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        let json = AnyResultsResponse(results: [["yolo": "yarr"]])

        let encoded: Data!
        do {
            encoded = try JSONEncoder().encode(json)
        } catch {
            XCTFail("Should encode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let query = GameScore.query

        let publisher = query.withCountExplainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

            }, receiveValue: { (queryResult: [[String: String]]) in
                XCTAssertEqual(queryResult, json.results)
        })
        publisher.store(in: &current)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testFirst() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        var scoreOnServer = GameScore(points: 10)
        scoreOnServer.points = 11
        scoreOnServer.objectId = "yolo"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let query = GameScore.query

        let publisher = query.firstPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { found in

            XCTAssert(found.hasSameObjectId(as: scoreOnServer))
        })
        publisher.store(in: &current)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testFirstExplain() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        let json = AnyResultsResponse(results: [["yolo": "yarr"]])

        let encoded: Data!
        do {
            encoded = try JSONEncoder().encode(json)
        } catch {
            XCTFail("Should encode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let query = GameScore.query

        let publisher = query.firstExplainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

            }, receiveValue: { (queryResult: [String: String]) in
                XCTAssertEqual(queryResult, json.results.first)
        })
        publisher.store(in: &current)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testCount() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        var scoreOnServer = GameScore(points: 10)
        scoreOnServer.points = 11
        scoreOnServer.objectId = "yolo"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let query = GameScore.query

        let publisher = query.countPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { found in

            XCTAssertEqual(found, 1)
        })
        publisher.store(in: &current)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testCountExplain() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        let json = AnyResultsResponse(results: [["yolo": "yarr"]])

        let encoded: Data!
        do {
            encoded = try JSONEncoder().encode(json)
        } catch {
            XCTFail("Should encode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let query = GameScore.query

        let publisher = query.countExplainPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

            }, receiveValue: { (queryResult: [[String: String]]) in
                XCTAssertEqual(queryResult, json.results)
        })
        publisher.store(in: &current)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testAggregate() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        var scoreOnServer = GameScore(points: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let query = GameScore.query
        let pipeline = [[String: AnyEncodable]]()
        let publisher = query.aggregatePublisher(pipeline)
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { found in

            guard let object = found.first else {
                XCTFail("Should have unwrapped")
                return
            }
            XCTAssert(object.hasSameObjectId(as: scoreOnServer))
        })
        publisher.store(in: &current)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testAggregateExplain() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        let json = AnyResultsResponse(results: [["yolo": "yarr"]])

        let encoded: Data!
        do {
            encoded = try JSONEncoder().encode(json)
        } catch {
            XCTFail("Should encode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let query = GameScore.query
        let pipeline = [[String: String]]()
        let publisher = query.aggregateExplainPublisher(pipeline)
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

            }, receiveValue: { (queryResult: [[String: String]]) in
                XCTAssertEqual(queryResult, json.results)
        })
        publisher.store(in: &current)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testDistinct() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        var scoreOnServer = GameScore(points: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let query = GameScore.query
        let publisher = query.distinctPublisher("hello")
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { found in

            guard let object = found.first else {
                XCTFail("Should have unwrapped")
                return
            }
            XCTAssert(object.hasSameObjectId(as: scoreOnServer))
        })
        publisher.store(in: &current)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testDistinctExplain() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        let json = AnyResultsResponse(results: [["yolo": "yarr"]])

        let encoded: Data!
        do {
            encoded = try JSONEncoder().encode(json)
        } catch {
            XCTFail("Should encode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let query = GameScore.query
        let publisher = query.distinctExplainPublisher("hello")
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

            }, receiveValue: { (queryResult: [[String: String]]) in
                XCTAssertEqual(queryResult, json.results)
        })
        publisher.store(in: &current)

        wait(for: [expectation1], timeout: 20.0)
    }
}

#endif
