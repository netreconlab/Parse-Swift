//
//  ParseQueryViewModelTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/3/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)
import Foundation
import XCTest
@testable import ParseSwift

// swiftlint:disable type_body_length

class ParseQueryViewModelTests: XCTestCase {
    struct GameScore: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        //: Your own properties
        var points: Int = 0

        // Custom initializer
        init() {}

        init(points: Int) {
            self.points = points
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
                                        usingPostForQuery: true,
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

    func testFind() async throws {
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
        let viewModel = GameScore.query
            .viewModel
        viewModel.error = ParseError(code: .otherCause, message: "error")
        await viewModel.find()

        guard let score = viewModel.results.first else {
            XCTFail("Should unwrap score count")
            return
        }
        XCTAssertTrue(score.hasSameObjectId(as: scoreOnServer))
        XCTAssertEqual(viewModel.count, 1)
        XCTAssertNil(viewModel.error)
    }

    func testFindError() async throws {

        let results = ParseError(code: .otherCause, message: "Custom error")
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        let viewModel = GameScore.query
            .viewModel
        viewModel.results = [GameScore(points: 10)]
        viewModel.count = 1
        await viewModel.find()

        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertEqual(viewModel.count, 0)
        XCTAssertNotNil(viewModel.error)
    }

    func testViewModelStatic() async throws {
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
        let viewModel = Query.viewModel(query)
        viewModel.error = ParseError(code: .otherCause, message: "error")
        await viewModel.find()

        guard let score = viewModel.results.first else {
            XCTFail("Should unwrap score count")
            return
        }
        XCTAssertTrue(score.hasSameObjectId(as: scoreOnServer))
        XCTAssertEqual(viewModel.count, 1)
        XCTAssertNil(viewModel.error)
    }

    func testFindAll() async throws {
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
        let viewModel = GameScore.query
            .viewModel
        viewModel.error = ParseError(code: .otherCause, message: "error")
        await viewModel.findAll()

        guard let score = viewModel.results.first else {
            XCTFail("Should unwrap score count")
            return
        }
        XCTAssertTrue(score.hasSameObjectId(as: scoreOnServer))
        XCTAssertEqual(viewModel.count, 1)
        XCTAssertNil(viewModel.error)
    }

    func testFindAllError() async throws {

        let results = ParseError(code: .otherCause, message: "Custom error")
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        let viewModel = GameScore.query
            .viewModel
        viewModel.results = [GameScore(points: 10)]
        viewModel.count = 1
        await viewModel.findAll()

        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertEqual(viewModel.count, 0)
        XCTAssertNotNil(viewModel.error)
    }

    func testFirst() async throws {
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
        let viewModel = GameScore.query
            .viewModel
        viewModel.error = ParseError(code: .otherCause, message: "error")
        await viewModel.first()

        guard let score = viewModel.results.first else {
            XCTFail("Should unwrap score count")
            return
        }
        XCTAssertTrue(score.hasSameObjectId(as: scoreOnServer))
        XCTAssertEqual(viewModel.count, 1)
        XCTAssertNil(viewModel.error)
    }

    func testFirstError() async throws {

        let results = ParseError(code: .otherCause, message: "Custom error")
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        let viewModel = GameScore.query
            .viewModel
        viewModel.results = [GameScore(points: 10)]
        viewModel.count = 1
        await viewModel.first()

        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertEqual(viewModel.count, 0)
        XCTAssertNotNil(viewModel.error)
    }

    func testCount() async throws {
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
        let viewModel = GameScore.query
            .viewModel
        viewModel.results = [GameScore(points: 10), GameScore(points: 12)]
        await viewModel.count()

        XCTAssertEqual(viewModel.results.count, 2)
        XCTAssertEqual(viewModel.count, 1)
        XCTAssertNil(viewModel.error)
    }

    func testCountError() async throws {

        let results = ParseError(code: .otherCause, message: "Custom error")
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        let viewModel = GameScore.query
            .viewModel
        viewModel.results = [GameScore(points: 10)]
        viewModel.count = 1
        await viewModel.count()

        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertEqual(viewModel.count, 0)
        XCTAssertNotNil(viewModel.error)
    }

    func testAggregate() async throws {
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
        let viewModel = GameScore.query
            .viewModel
        viewModel.error = ParseError(code: .otherCause, message: "error")
        await viewModel.aggregate([["hello": "world"]])

        guard let score = viewModel.results.first else {
            XCTFail("Should unwrap score count")
            return
        }
        XCTAssertTrue(score.hasSameObjectId(as: scoreOnServer))
        XCTAssertEqual(viewModel.count, 1)
        XCTAssertNil(viewModel.error)
    }

    func testAggregateError() async throws {

        let results = ParseError(code: .otherCause, message: "Custom error")
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        let viewModel = GameScore.query.viewModel
        viewModel.results = [GameScore(points: 10)]
        viewModel.count = 1
        await viewModel.aggregate([["hello": "world"]])

        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertEqual(viewModel.count, 0)
        XCTAssertNotNil(viewModel.error)
    }
}
#endif
