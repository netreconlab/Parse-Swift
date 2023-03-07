//
//  ParseOperationCombineTests.swift
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

class ParseOperationCombineTests: XCTestCase {

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

    func testSave() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        var score = GameScore(points: 10)
        score.objectId = "yarr"
        let operations = score.operation
            .increment("points", by: 1)

        var scoreOnServer = score
        scoreOnServer.points = 11
        scoreOnServer.updatedAt = Date()
        scoreOnServer.ACL = nil

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

        let publisher = operations.savePublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { saved in

            XCTAssert(saved.hasSameObjectId(as: scoreOnServer))
            guard let savedUpdatedAt = saved.updatedAt else {
                XCTFail("Should unwrap dates")
                return
            }
            guard let originalUpdatedAt = scoreOnServer.updatedAt else {
                XCTFail("Should unwrap dates")
                return
            }
            XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(saved.ACL)
        })
        publisher.store(in: &current)

        wait(for: [expectation1], timeout: 20.0)
    }
}

#endif
