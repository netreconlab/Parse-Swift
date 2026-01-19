//
//  ParsePointerCombineTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 4/20/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)

import Foundation
import XCTest
import Combine
@testable import ParseSwift

class ParsePointerCombineTests: XCTestCase, @unchecked Sendable {

    struct GameScore: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        //: Your own properties
        var points: Int

        //: a custom initializer
        init() {
            self.points = 5
        }
        init(points: Int) {
            self.points = points
        }
    }

    override func setUp() async throws {
        try await super.setUp()
        guard let url = URL(string: "http://localhost:1337/parse") else {
            throw ParseError(code: .otherCause, message: "Should create valid URL")
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

    func testFetch() throws {
        var score = GameScore(points: 10)
        let objectId = "yarr"
        score.objectId = objectId
        let pointer = try score.toPointer()

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Fetch")

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(scoreOnServer)
            // Get dates in correct format from ParseDecoding strategy
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = pointer.fetchPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { fetched in

            XCTAssert(fetched.hasSameObjectId(as: scoreOnServer))
            guard let fetchedCreatedAt = fetched.createdAt,
                let fetchedUpdatedAt = fetched.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = scoreOnServer.createdAt,
                let originalUpdatedAt = scoreOnServer.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
            XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(fetched.ACL)
        })
        publisher.store(in: &current)

        wait(for: [expectation1], timeout: 20.0)
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func testFetchAll() throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Fetch")

        let score = GameScore(points: 10)
        let score2 = GameScore(points: 20)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        var scoreOnServer2 = score2
        scoreOnServer2.objectId = "yolo"
        scoreOnServer2.createdAt = Calendar.current.date(byAdding: .init(day: -2), to: Date())
        scoreOnServer2.updatedAt = scoreOnServer2.createdAt
        scoreOnServer2.ACL = nil

        let response = QueryResponse<GameScore>(results: [scoreOnServer, scoreOnServer2], count: 2)
        let encoded: Data!
        do {
           encoded = try ParseCoding.jsonEncoder().encode(response)
           // Get dates in correct format from ParseDecoding strategy
           let encoded1 = try ParseCoding.jsonEncoder().encode(scoreOnServer)
           scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded1)
           let encoded2 = try ParseCoding.jsonEncoder().encode(scoreOnServer2)
           scoreOnServer2 = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded2)

        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200)
        }

        let pointers = try [
            GameScore(objectId: "yarr").toPointer(),
            GameScore(objectId: "yolo").toPointer()
        ]

        let publisher = pointers.fetchAllPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { fetched in

            XCTAssertEqual(fetched.count, 2)
            guard let firstObject = try? fetched.first(where: {try $0.get().objectId == "yarr"}),
                let secondObject = try? fetched.first(where: {try $0.get().objectId == "yolo"}) else {
                    XCTFail("Should unwrap")
                    return
            }

            switch firstObject {

            case .success(let first):
                XCTAssert(first.hasSameObjectId(as: scoreOnServer))
                guard let fetchedCreatedAt = first.createdAt,
                    let fetchedUpdatedAt = first.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt = scoreOnServer.createdAt,
                    let originalUpdatedAt = scoreOnServer.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(first.ACL)
                XCTAssertEqual(first.points, scoreOnServer.points)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            switch secondObject {

            case .success(let second):
                XCTAssert(second.hasSameObjectId(as: scoreOnServer2))
                guard let savedCreatedAt = second.createdAt,
                    let savedUpdatedAt = second.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt = scoreOnServer2.createdAt,
                    let originalUpdatedAt = scoreOnServer2.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(second.ACL)
                XCTAssertEqual(second.points, scoreOnServer2.points)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        })
        publisher.store(in: &current)

        wait(for: [expectation1], timeout: 20.0)
    }
}

#endif
