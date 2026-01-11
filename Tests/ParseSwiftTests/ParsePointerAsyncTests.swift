//
//  ParsePointerAsyncTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 11/1/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

// Currently can't takeover URLSession with MockURLProtocol
// on Linux, Windows, etc. so disabling networking tests on
// those platforms.
#if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

class ParsePointerAsyncTests: XCTestCase, @unchecked Sendable {

    struct GameScore: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        //: Your own properties
        var points: Int
        var other: Pointer<GameScore>?
        var others: [Pointer<GameScore>]?

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

    @MainActor
    func testFetch() async throws {
        var score = GameScore(points: 10)
        let objectId = "yarr"
        score.objectId = objectId
        let pointer = try score.toPointer()

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil
        let encoded: Data!
        do {
            encoded = try scoreOnServer.getEncoder().encode(scoreOnServer, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        do {
            let fetched = try await pointer.fetch(options: [])
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
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    @MainActor
    func testDetectCircularDependency() async throws {
        var score = GameScore(points: 10)
        score.objectId = "nice"
        score.other = try score.toPointer()

        do {
            _ = try await score.ensureDeepSave()
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have failed with an error of detecting a circular dependency")
                return
            }
            XCTAssertTrue(parseError.message.contains("circular"))
        }
    }

    @MainActor
    func testDetectCircularDependencyArray() async throws {
        var score = GameScore(points: 10)
        score.objectId = "nice"
        let first = try score.toPointer()
        score.others = [first, first]

        do {
            _ = try await score.ensureDeepSave()
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have failed with an error of detecting a circular dependency")
                return
            }
            XCTAssertTrue(parseError.message.contains("circular"))
        }
    }
}
#endif
