//
//  ParsePointerTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 10/25/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

// swiftlint:disable type_body_length

class ParsePointerTests: XCTestCase {

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
        #if !os(Linux) && !os(Android) && !os(Windows)
        try await KeychainStore.shared.deleteAll()
        #endif
        try await ParseStorage.shared.deleteAll()
    }

    func testPointer() throws {
        var score = GameScore(points: 10)
        score.objectId = "yarr"
        let pointer = try score.toPointer()
        let initializedPointer = try Pointer(score)
        XCTAssertEqual(pointer.className, score.className)
        XCTAssertEqual(pointer.objectId, score.objectId)
        XCTAssertEqual(pointer.className, initializedPointer.className)
        XCTAssertEqual(pointer.objectId, initializedPointer.objectId)
    }

    func testDebugString() throws {
        var score = GameScore(points: 10)
        score.objectId = "yarr"
        let pointer = try score.toPointer()
        XCTAssertEqual(pointer.debugDescription,
                       "{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"yarr\"}")
        XCTAssertEqual(pointer.description,
                       "{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"yarr\"}")
    }

    func testPointerNoObjectId() throws {
        let score = GameScore(points: 10)
        XCTAssertThrowsError(try Pointer(score))
    }

    func testPointerObjectId() throws {
        let score = Pointer<GameScore>(objectId: "yarr")
        var score2 = GameScore(points: 10)
        score2.objectId = "yarr"
        let pointer = try score2.toPointer()
        XCTAssertEqual(pointer.className, score.className)
        XCTAssertEqual(pointer.objectId, score.objectId)
    }

    func testHasSameObjectId() throws {
        var score = GameScore(points: 10)
        let objectId = "yarr"
        score.objectId = objectId
        let pointer = try score.toPointer()
        let pointer2 = pointer
        XCTAssertTrue(pointer.hasSameObjectId(as: pointer2))
        XCTAssertTrue(pointer.hasSameObjectId(as: score))
        score.objectId = "hello"
        let pointer3 = try score.toPointer()
        XCTAssertFalse(pointer.hasSameObjectId(as: pointer3))
        XCTAssertFalse(pointer.hasSameObjectId(as: score))
    }

    func testPointerEquality() throws {
        var score = GameScore(points: 10)
        let objectId = "yarr"
        score.objectId = objectId
        let pointer = try score.toPointer()
        var score2 = GameScore(points: 10)
        score2.objectId = objectId
        var pointer2 = try score2.toPointer()
        XCTAssertEqual(pointer, pointer2)
        pointer2.objectId = "hello"
        XCTAssertNotEqual(pointer, pointer2)
    }

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

    // swiftlint:disable:next function_body_length
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

        do {
            let fetched = try await pointer.fetch(
                includeKeys: [],
                options: []
            )
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

        do {
            let fetched = try await pointer.fetch(options: [.usePrimaryKey])
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

    // swiftlint:disable:next function_body_length
    func fetchAsync(score: Pointer<GameScore>, scoreOnServer: GameScore, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Fetch object1")
        score.fetch(options: [], callbackQueue: callbackQueue) { result in

            switch result {
            case .success(let fetched):
                XCTAssert(fetched.hasSameObjectId(as: scoreOnServer))
                guard let fetchedCreatedAt = fetched.createdAt,
                    let fetchedUpdatedAt = fetched.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                }
                guard let originalCreatedAt = scoreOnServer.createdAt,
                    let originalUpdatedAt = scoreOnServer.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                }
                XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(fetched.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "Fetch object2")
        score.fetch(options: [.usePrimaryKey], callbackQueue: callbackQueue) { result in

            switch result {
            case .success(let fetched):
                XCTAssert(fetched.hasSameObjectId(as: scoreOnServer))
                guard let fetchedCreatedAt = fetched.createdAt,
                    let fetchedUpdatedAt = fetched.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation2.fulfill()
                        return
                }
                guard let originalCreatedAt = scoreOnServer.createdAt,
                    let originalUpdatedAt = scoreOnServer.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation2.fulfill()
                        return
                }
                XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(fetched.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testEncodeEmbeddedPointer() throws {
        var score = GameScore(points: 10)
        let objectId = "yarr"
        score.objectId = objectId

        var score2 = GameScore(points: 50)
        score2.other = try score.toPointer()

        let encoded = try score2.getEncoder().encode(score2,
                                                     collectChildren: false,
                                                     objectsSavedBeforeThisOne: nil,
                                                     filesSavedBeforeThisOne: nil)

        let decoded = String(decoding: encoded.encoded, as: UTF8.self)
        XCTAssertEqual(decoded,
                       // swiftlint:disable:next line_length
                       "{\"other\":{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"yarr\"},\"points\":50}")
        XCTAssertNil(encoded.unique)
        XCTAssertEqual(encoded.unsavedChildren.count, 0)
    }

    func testPointerTypeEncoding() throws {
        var score = GameScore(points: 10)
        let objectId = "yarr"
        score.objectId = objectId

        let pointerType = try PointerType(score)

        let encoded = try ParseCoding.parseEncoder().encode(pointerType)
        let decoded = String(decoding: encoded, as: UTF8.self)
        XCTAssertEqual(decoded,
                       "{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"yarr\"}")
    }

    // Thread tests randomly fail on linux
    #if !os(Linux) && !os(Android) && !os(Windows)
    func testThreadSafeFetchAsync() throws {
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
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        DispatchQueue.concurrentPerform(iterations: 1) { _ in
            self.fetchAsync(score: pointer, scoreOnServer: scoreOnServer, callbackQueue: .global(qos: .background))
        }
    }
    #endif

    func testFetchAsyncMainQueue() throws {
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
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        self.fetchAsync(score: pointer, scoreOnServer: scoreOnServer, callbackQueue: .main)
    }

    @MainActor
    func testFetchAll() async throws { // swiftlint:disable:this function_body_length
        let score = GameScore(points: 10)
        let score2 = GameScore(points: 20)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil
        let scoreOnServerImmutable: GameScore!
        let scoreOnServer2Immutable: GameScore!
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
           scoreOnServerImmutable = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded1)
           let encoded2 = try ParseCoding.jsonEncoder().encode(scoreOnServer2)
           scoreOnServer2Immutable = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded2)

        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200)
        }

        let fetched = try await [
            GameScore(objectId: "yarr").toPointer(),
            GameScore(objectId: "yolo").toPointer()
        ].fetchAll()

        XCTAssertEqual(fetched.count, 2)
        guard let firstObject = try? fetched.first(where: {try $0.get().objectId == "yarr"}),
            let secondObject = try? fetched.first(where: {try $0.get().objectId == "yolo"}) else {
                XCTFail("Should unwrap")
                return
        }

        switch firstObject {

        case .success(let first):
            XCTAssert(first.hasSameObjectId(as: scoreOnServerImmutable))
            guard let fetchedCreatedAt = first.createdAt,
                let fetchedUpdatedAt = first.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = scoreOnServerImmutable.createdAt,
                let originalUpdatedAt = scoreOnServerImmutable.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
            XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(first.ACL)
            XCTAssertEqual(first.points, scoreOnServerImmutable.points)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }

        switch secondObject {

        case .success(let second):
            XCTAssert(second.hasSameObjectId(as: scoreOnServer2Immutable))
            guard let savedCreatedAt = second.createdAt,
                let savedUpdatedAt = second.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = scoreOnServer2Immutable.createdAt,
                let originalUpdatedAt = scoreOnServer2Immutable.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(savedCreatedAt, originalCreatedAt)
            XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(second.ACL)
            XCTAssertEqual(second.points, scoreOnServer2Immutable.points)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

}
