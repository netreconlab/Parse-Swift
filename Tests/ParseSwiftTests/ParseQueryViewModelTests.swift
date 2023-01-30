//
//  ParseQueryViewModelTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/3/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if canImport(SwiftUI)
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
        try ParseSwift.initialize(applicationId: "applicationId",
                                  clientKey: "clientKey",
                                  primaryKey: "primaryKey",
                                  serverURL: url,
                                  usingPostForQuery: true,
                                  testing: true)
    }

    override func tearDown() async throws {
        try await super.tearDown()
        MockURLProtocol.removeAll()
        try await KeychainStore.shared.deleteAll()
        try await ParseStorage.shared.deleteAll()
    }

    func testFind() {
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
        viewModel.find()
        let expectation = XCTestExpectation(description: "Find objects")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {

            guard let score = viewModel.results.first else {
                XCTFail("Should unwrap score count")
                expectation.fulfill()
                return
            }
            XCTAssertTrue(score.hasSameObjectId(as: scoreOnServer))
            XCTAssertEqual(viewModel.count, 1)
            XCTAssertNil(viewModel.error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testFindError() {

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
        viewModel.find()
        let expectation = XCTestExpectation(description: "Find objects")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {

            XCTAssertTrue(viewModel.results.isEmpty)
            XCTAssertEqual(viewModel.count, 0)
            XCTAssertNotNil(viewModel.error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testViewModelStatic() {
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
        viewModel.find()
        let expectation = XCTestExpectation(description: "Find objects")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {

            guard let score = viewModel.results.first else {
                XCTFail("Should unwrap score count")
                expectation.fulfill()
                return
            }
            XCTAssertTrue(score.hasSameObjectId(as: scoreOnServer))
            XCTAssertEqual(viewModel.count, 1)
            XCTAssertNil(viewModel.error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testFindAll() {
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
        viewModel.findAll()
        let expectation = XCTestExpectation(description: "Find objects")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {

            guard let score = viewModel.results.first else {
                XCTFail("Should unwrap score count")
                expectation.fulfill()
                return
            }
            XCTAssertTrue(score.hasSameObjectId(as: scoreOnServer))
            XCTAssertEqual(viewModel.count, 1)
            XCTAssertNil(viewModel.error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testFindAllError() {

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
        viewModel.findAll()
        let expectation = XCTestExpectation(description: "Find objects")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {

            XCTAssertTrue(viewModel.results.isEmpty)
            XCTAssertEqual(viewModel.count, 0)
            XCTAssertNotNil(viewModel.error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testFirst() {
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
        viewModel.first()
        let expectation = XCTestExpectation(description: "Find objects")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {

            guard let score = viewModel.results.first else {
                XCTFail("Should unwrap score count")
                expectation.fulfill()
                return
            }
            XCTAssertTrue(score.hasSameObjectId(as: scoreOnServer))
            XCTAssertEqual(viewModel.count, 1)
            XCTAssertNil(viewModel.error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testFirstError() {

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
        viewModel.first()
        let expectation = XCTestExpectation(description: "Find objects")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {

            XCTAssertTrue(viewModel.results.isEmpty)
            XCTAssertEqual(viewModel.count, 0)
            XCTAssertNotNil(viewModel.error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testCount() {
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
        viewModel.count()
        let expectation = XCTestExpectation(description: "Find objects")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {

            XCTAssertEqual(viewModel.results.count, 2)
            XCTAssertEqual(viewModel.count, 1)
            XCTAssertNil(viewModel.error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testCountError() {

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
        viewModel.count()
        let expectation = XCTestExpectation(description: "Find objects")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {

            XCTAssertTrue(viewModel.results.isEmpty)
            XCTAssertEqual(viewModel.count, 0)
            XCTAssertNotNil(viewModel.error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testAggregate() {
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
        viewModel.aggregate([["hello": "world"]])
        let expectation = XCTestExpectation(description: "Find objects")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {

            guard let score = viewModel.results.first else {
                XCTFail("Should unwrap score count")
                expectation.fulfill()
                return
            }
            XCTAssertTrue(score.hasSameObjectId(as: scoreOnServer))
            XCTAssertEqual(viewModel.count, 1)
            XCTAssertNil(viewModel.error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testAggregateError() {

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
        viewModel.aggregate([["hello": "world"]])
        let expectation = XCTestExpectation(description: "Find objects")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {

            XCTAssertTrue(viewModel.results.isEmpty)
            XCTAssertEqual(viewModel.count, 0)
            XCTAssertNotNil(viewModel.error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }
}
#endif
