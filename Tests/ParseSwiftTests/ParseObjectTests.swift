//
//  ParseObjectCommandTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 7/19/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseObjectTests: XCTestCase { // swiftlint:disable:this type_body_length
    struct Level: ParseObject {
        var objectId: String?

        var createdAt: Date?

        var updatedAt: Date?

        var ACL: ParseACL?

        var name: String?

        var originalData: Data?

        init() {
            name = "First"
        }
    }

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
        var level: Level?
        var levels: [Level]?
        var nextLevel: Level?

        //: custom initializers
        init() {}

        init(points: Int) {
            self.points = points
            self.player = "Jen"
        }

        init(points: Int, name: String) {
            self.points = points
            self.player = name
        }

        //: Implement your own version of merge
        func merge(with object: Self) throws -> Self {
            var updated = try mergeParse(with: object)
            if updated.shouldRestoreKey(\.points,
                                         original: object) {
                updated.points = object.points
            }
            if updated.shouldRestoreKey(\.level,
                                         original: object) {
                updated.level = object.level
            }
            if updated.shouldRestoreKey(\.levels,
                                         original: object) {
                updated.levels = object.levels
            }
            if updated.shouldRestoreKey(\.nextLevel,
                                         original: object) {
                updated.nextLevel = object.nextLevel
            }
            return updated
        }
    }

    struct Game: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        //: Your own properties
        var gameScore: GameScore
        var gameScores = [GameScore]()
        var name = "Hello"
        var profilePicture: ParseFile?

        //: a custom initializer
        init() {
            self.gameScore = GameScore()
        }

        init(gameScore: GameScore) {
            self.gameScore = gameScore
        }
    }

    struct GameDefaultMerge: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        //: Your own properties
        var gameScore: GameScore?
        var gameScores: [GameScore]?
        var name: String?
        var profilePicture: ParseFile?
    }

    struct Game2: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        //: Your own properties
        var name = "Hello"
        var profilePicture: ParseFile?
    }

    final class GameScoreClass: ParseObject {

        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        //: Your own properties
        var points: Int
        var player = "Jen"
        var level: Level?
        var levels: [Level]?
        var game: GameClass?

        //: a custom initializer
        required init() {
            self.points = 5
        }

        init(points: Int) {
            self.points = points
        }

        public static func == (
            lhs: ParseObjectTests.GameScoreClass,
            rhs: ParseObjectTests.GameScoreClass
        ) -> Bool {
            lhs.hasSameObjectId(as: rhs)
                && lhs.createdAt == rhs.createdAt
                && lhs.updatedAt == rhs.updatedAt
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(self.id)
            hasher.combine(createdAt)
            hasher.combine(updatedAt)
        }
    }

    final class GameClass: ParseObject {

        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        //: Your own properties
        var gameScore: GameScoreClass
        var gameScores = [GameScore]()
        var name = "Hello"

        //: a custom initializer
        required init() {
            self.gameScore = GameScoreClass()
        }

        init(gameScore: GameScoreClass) {
            self.gameScore = gameScore
        }

        public static func == (lhs: ParseObjectTests.GameClass, rhs: ParseObjectTests.GameClass) -> Bool {
            lhs.hasSameObjectId(as: rhs) &&
            lhs.createdAt == rhs.createdAt &&
            lhs.updatedAt == rhs.updatedAt
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(self.id)
            hasher.combine(createdAt)
            hasher.combine(updatedAt)
        }
    }

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
        var sessionToken: String?
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

    func loginNormally() async throws -> User {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        let user = try await User.login(username: "parse", password: "user")
        MockURLProtocol.removeAll()
        return user
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

        guard let fileManager = ParseFileManager() else {
            throw ParseError(code: .otherCause, message: "Should have initialized file manage")
        }

        let directory2 = try ParseFileManager.downloadDirectory()
        try? fileManager.removeDirectoryContents(directory2)
    }

    func testReplaceResponseMissingObjectId() throws {
        let object = User()
        let response = ReplaceResponse(
            createdAt: Date(),
            updatedAt: Date(),
            sessionToken: "hello"
        )
        do {
            _ = try response.setResponseProperties(on: object)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.containedIn([.missingObjectId]))
        }
    }

    func testIsEqualExtension() throws {
        let score1 = GameScore(points: 2)
        let score2 = GameScore(points: 3)
        XCTAssertFalse(score1.isEqual(score2))
    }

    func testId() throws {
        var score = GameScore()
        let objectId = "yolo"
        XCTAssertNotNil(UUID(uuidString: score.id))
        XCTAssertNotEqual(score.id, objectId)
        score.objectId = "yolo"
        XCTAssertEqual(score.id, objectId)
    }

    func testIsRestoreOriginalKey() throws {
        let score1 = GameScore(points: 5)
        var score2 = GameScore(points: 5, name: "world")
        score2.levels = [Level()]
        score2.nextLevel = Level()
        XCTAssertFalse(score1.shouldRestoreKey(\.player, original: score2))
        XCTAssertTrue(score1.shouldRestoreKey(\.levels, original: score2))
        XCTAssertFalse(score1.shouldRestoreKey(\.points, original: score2))
        XCTAssertFalse(score1.shouldRestoreKey(\.level, original: score2))
        XCTAssertTrue(score1.shouldRestoreKey(\.nextLevel, original: score2))
    }

    func testParseObjectMutable() throws {
        var score = GameScore(points: 19, name: "fire")
        XCTAssertEqual(score, score.mergeable)
        score.objectId = "yolo"
        score.createdAt = Date()
        var empty = score.mergeable
        XCTAssertNotNil(empty.originalData)
        XCTAssertTrue(score.hasSameObjectId(as: empty))
        XCTAssertEqual(score.createdAt, empty.createdAt)
        empty.player = "Ali"
        XCTAssertEqual(empty.originalData, empty.mergeable.originalData)
    }

    func testMerge() throws {
        var score = GameScore(points: 19, name: "fire")
        score.objectId = "yolo"
        score.createdAt = Date()
        score.updatedAt = Date()
        var acl = ParseACL()
        acl.publicRead = true
        score.ACL = acl
        var level = Level()
        level.objectId = "hello"
        var level2 = Level()
        level2.objectId = "world"
        score.level = level
        score.levels = [level]
        score.nextLevel = level2
        var updated = score.mergeable
        updated.updatedAt = Calendar.current.date(byAdding: .init(day: 1), to: Date())
        updated.points = 30
        updated.player = "moreFire"
        updated.levels = [level, level2]
        let merged = try updated.merge(with: score)
        XCTAssertEqual(merged.points, updated.points)
        XCTAssertEqual(merged.player, updated.player)
        XCTAssertEqual(merged.level, score.level)
        XCTAssertEqual(merged.levels, updated.levels)
        XCTAssertEqual(merged.nextLevel, score.nextLevel)
        XCTAssertEqual(merged.ACL, score.ACL)
        XCTAssertEqual(merged.createdAt, score.createdAt)
        XCTAssertEqual(merged.updatedAt, updated.updatedAt)
    }

    func testMergeDefaultImplementation() throws {
        var score = GameDefaultMerge()
        score.objectId = "yolo"
        score.createdAt = Date()
        score.updatedAt = Date()
        var updated = score.set(\.name, to: "moreFire")
        updated.updatedAt = Calendar.current.date(byAdding: .init(day: 1), to: Date())
        score.updatedAt = updated.updatedAt
        score.name = updated.name
        var merged = try updated.merge(with: score)
        merged.originalData = nil
        // Get dates in correct format from ParseDecoding strategy
        let encoded = try ParseCoding.jsonEncoder().encode(score)
        score = try ParseCoding.jsonDecoder().decode(GameDefaultMerge.self, from: encoded)
        XCTAssertEqual(merged, score)
    }

    func testMergeDifferentObjectId() throws {
        var score = GameScore(points: 19, name: "fire")
        score.objectId = "yolo"
        var score2 = score
        score2.objectId = "nolo"
        XCTAssertThrowsError(try score2.merge(with: score))
    }

    func testRevertObject() throws {
        var score = GameScore(points: 19, name: "fire")
        score.objectId = "yolo"
        var mutableScore = score.mergeable
        mutableScore.points = 50
        mutableScore.player = "ali"
        XCTAssertNotEqual(mutableScore, score)
        mutableScore = try mutableScore.revert()
        XCTAssertEqual(mutableScore, score)
    }

    func testRevertObjectMissingOriginal() throws {
        var score = GameScore(points: 19, name: "fire")
        score.objectId = "yolo"
        var mutableScore = score
        mutableScore.points = 50
        mutableScore.player = "ali"
        XCTAssertNotEqual(mutableScore, score)
        do {
            mutableScore = try mutableScore.revert()
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("Missing original"))
        }
    }

    func testRevertObjectDiffObjectId() throws {
        var score = GameScore(points: 19, name: "fire")
        score.objectId = "yolo"
        var mutableScore = score.mergeable
        mutableScore.points = 50
        mutableScore.player = "ali"
        mutableScore.objectId = "nolo"
        XCTAssertNotEqual(mutableScore, score)
        do {
            mutableScore = try mutableScore.revert()
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("objectId as the original"))
        }
    }

    func testRevertKeyPath() throws {
        var score = GameScore(points: 19, name: "fire")
        score.objectId = "yolo"
        var mutableScore = score.mergeable
        mutableScore.points = 50
        mutableScore.player = "ali"
        XCTAssertNotEqual(mutableScore, score)
        mutableScore = try mutableScore.revert(\.player)
        XCTAssertNotEqual(mutableScore, score)
        XCTAssertEqual(mutableScore.objectId, score.objectId)
        XCTAssertNotEqual(mutableScore.points, score.points)
        XCTAssertEqual(mutableScore.player, score.player)
    }

    func testRevertKeyPathUpdatedNil() throws {
        var score = GameScore(points: 19, name: "fire")
        score.objectId = "yolo"
        var mutableScore = score.mergeable
        mutableScore.points = 50
        mutableScore.player = nil
        XCTAssertNotEqual(mutableScore, score)
        mutableScore = try mutableScore.revert(\.player)
        XCTAssertNotEqual(mutableScore, score)
        XCTAssertEqual(mutableScore.objectId, score.objectId)
        XCTAssertNotEqual(mutableScore.points, score.points)
        XCTAssertEqual(mutableScore.player, score.player)
    }

    func testRevertKeyPathOriginalNil() throws {
        var score = GameScore(points: 19, name: "fire")
        score.objectId = "yolo"
        score.player = nil
        var mutableScore = score.mergeable
        mutableScore.points = 50
        mutableScore.player = "ali"
        XCTAssertNotEqual(mutableScore, score)
        mutableScore = try mutableScore.revert(\.player)
        XCTAssertNotEqual(mutableScore, score)
        XCTAssertEqual(mutableScore.objectId, score.objectId)
        XCTAssertNotEqual(mutableScore.points, score.points)
        XCTAssertEqual(mutableScore.player, score.player)
    }

    func testRevertKeyPathMissingOriginal() throws {
        var score = GameScore(points: 19, name: "fire")
        score.objectId = "yolo"
        var mutableScore = score
        mutableScore.points = 50
        mutableScore.player = "ali"
        XCTAssertNotEqual(mutableScore, score)
        do {
            mutableScore = try mutableScore.revert(\.player)
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("Missing original"))
        }
    }

    func testRevertKeyPathDiffObjectId() throws {
        var score = GameScore(points: 19, name: "fire")
        score.objectId = "yolo"
        var mutableScore = score.mergeable
        mutableScore.points = 50
        mutableScore.player = "ali"
        mutableScore.objectId = "nolo"
        XCTAssertNotEqual(mutableScore, score)
        do {
            mutableScore = try mutableScore.revert(\.player)
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("objectId as the original"))
        }
    }

    func testGet() throws {
        let originalPoints = 10
        let score = GameScore(points: originalPoints)
        let points = try score.get(\.points)
        XCTAssertEqual(points, originalPoints)
        do {
            try score.get(\.ACL)
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("unwrap"))
        }
    }

    func testIsDirtyForKey() throws {
        var score = GameScore(objectId: "hello")
        score.objectId = "world"
        score.points = 15
        XCTAssertFalse(try score.isDirtyForKey(\.points))
        score = score.set(\.points, to: 20)
        XCTAssertTrue(try score.isDirtyForKey(\.points))
        score = score.set(\.points, to: 15)
        XCTAssertFalse(try score.isDirtyForKey(\.points))
        XCTAssertFalse(try score.isDirtyForKey(\.player))
        score = score.set(\.player, to: "yolo")
        XCTAssertTrue(try score.isDirtyForKey(\.player))
    }

    func testFetchCommand() {
        var score = GameScore(points: 10)
        let className = score.className
        XCTAssertThrowsError(try score.fetchCommand(include: nil))
        let objectId = "yarr"
        score.objectId = objectId
        do {
            let command = try score.fetchCommand(include: nil)
            XCTAssertNotNil(command)
            XCTAssertEqual(command.path.urlComponent, "/classes/\(className)/\(objectId)")
            XCTAssertEqual(command.method, API.Method.GET)
            XCTAssertNil(command.params)
            XCTAssertNil(command.body)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testFetchIncludeCommand() {
        var score = GameScore(points: 10)
        let className = score.className
        let objectId = "yarr"
        score.objectId = objectId
        let includeExpected = ["include": "[\"yolo\", \"test\"]"]
        do {
            let command = try score.fetchCommand(include: ["yolo", "test"])
            XCTAssertNotNil(command)
            XCTAssertEqual(command.path.urlComponent, "/classes/\(className)/\(objectId)")
            XCTAssertEqual(command.method, API.Method.GET)
            XCTAssertEqual(command.params?.keys.first, includeExpected.keys.first)
            if let value = command.params?.values.first,
                let includeValue = value {
                XCTAssertTrue(includeValue.contains("\"yolo\""))
            } else {
                XCTFail("Should have unwrapped value")
            }
            XCTAssertNil(command.body)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // swiftlint:disable:next function_body_length
    func testFetch() async throws {
        var score = GameScore(points: 10)
        let objectId = "yarr"
        score.objectId = objectId

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(scoreOnServer)
            // Get dates in correct format from ParseDecoding strategy
            scoreOnServer = try GameScore.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        do {
            let fetched = try await score.fetch(options: [])
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
            let fetched = try await score.fetch(options: [.usePrimaryKey])
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

    func testFetchBasedOnObjectId() async throws {
        var score = GameScore(points: 10)
        let objectId = "yarr"
        score.objectId = objectId

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
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
        do {
            var fetched = GameScore(objectId: objectId)
            fetched = try await fetched.fetch(options: [])
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
            XCTAssertEqual(fetched.points, score.points)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // swiftlint:disable:next function_body_length
    func fetchAsync(score: GameScore, scoreOnServer: GameScore, callbackQueue: DispatchQueue) {

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
                XCTAssertEqual(fetched.points, scoreOnServer.points)
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
                XCTAssertEqual(fetched.points, scoreOnServer.points)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func testThreadSafeFetchAsync() {
        var score = GameScore(points: 10)
        let objectId = "yarr"
        score.objectId = objectId

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(scoreOnServer)
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
            self.fetchAsync(score: score, scoreOnServer: scoreOnServer, callbackQueue: .global(qos: .background))
        }
    }
    #endif

    func testFetchAsyncMainQueue() {
        var score = GameScore(points: 10)
        let objectId = "yarr"
        score.objectId = objectId

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(scoreOnServer)
            // Get dates in correct format from ParseDecoding strategy
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        self.fetchAsync(score: score, scoreOnServer: scoreOnServer, callbackQueue: .main)
    }

    func testSaveCommand() async throws {
        let score = GameScore(points: 10)
        let className = score.className

        let command = try await score.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/classes/\(className)")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)

        let expected = "GameScore ({\"player\":\"Jen\",\"points\":10})"
        let decoded = score.debugDescription
        XCTAssertEqual(decoded, expected)
        let expected2 = "GameScore ({\"player\":\"Jen\",\"points\":10})"
        let decoded2 = score.description
        XCTAssertEqual(decoded2, expected2)
    }

    func testSaveUpdateCommand() async throws {
        var score = GameScore(points: 10)
        let className = score.className
        let objectId = "yarr"
        score.objectId = objectId
        score.createdAt = Date()
        score.updatedAt = score.createdAt

        let command = try await score.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/classes/\(className)/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)

        guard let body = command.body else {
            XCTFail("Should be able to unwrap")
            return
        }

        let expected = "{\"player\":\"Jen\",\"points\":10}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testSaveUpdateCommandParseObjectMutable() async throws {
        var score = GameScore(points: 10)
        let className = score.className
        let objectId = "yarr"
        score.objectId = objectId
        score.createdAt = Date()
        score.updatedAt = score.createdAt

        let command = try await score.mergeable.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/classes/\(className)/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)

        guard let body = command.body else {
            XCTFail("Should be able to unwrap")
            return
        }

        let expected = "{}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)

        var empty = score.mergeable
        empty.player = "Jennifer"
        let command2 = try await empty.saveCommand()
        guard let body2 = command2.body else {
            XCTFail("Should be able to unwrap")
            return
        }
        let expected2 = "{\"player\":\"Jennifer\"}"
        let encoded2 = try ParseCoding.parseEncoder()
            .encode(body2, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded2 = String(decoding: encoded2, as: UTF8.self)
        XCTAssertEqual(decoded2, expected2)
    }

    func testCreateCommand() async throws {
        let score = GameScore(points: 10)

        let command = try await score.createCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/classes/\(score.className)")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
    }

    func testReplaceCommand() throws {
        var score = GameScore(points: 10)
        XCTAssertThrowsError(try score.replaceCommand())
        let objectId = "yarr"
        score.objectId = objectId

        let command = try score.replaceCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/classes/\(score.className)/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
    }

    func testUpdateCommand() throws {
        var score = GameScore(points: 10)
        XCTAssertThrowsError(try score.updateCommand())
        let objectId = "yarr"
        score.objectId = objectId

        let command = try score.updateCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/classes/\(score.className)/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PATCH)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
    }

    func testSave() async throws {
        let score = GameScore(points: 10)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()

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
        do {
            let saved = try await score.save()
            XCTAssert(saved.hasSameObjectId(as: scoreOnServer))
            guard let savedCreatedAt = saved.createdAt,
                let savedUpdatedAt = saved.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(savedCreatedAt, scoreOnServer.createdAt)
            XCTAssertEqual(savedUpdatedAt, scoreOnServer.createdAt)
            XCTAssertEqual(saved.ACL, scoreOnServer.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let saved = try await score.save(options: [.usePrimaryKey])
            XCTAssert(saved.hasSameObjectId(as: scoreOnServer))
            guard let savedCreatedAt = saved.createdAt,
                let savedUpdatedAt = saved.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(savedCreatedAt, scoreOnServer.createdAt)
            XCTAssertEqual(savedUpdatedAt, scoreOnServer.createdAt)
            XCTAssertEqual(saved.ACL, scoreOnServer.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveWithDefaultACL() async throws {
        let user = try await loginNormally()
        guard let userObjectId = user.objectId else {
            XCTFail("Should have objectId")
            return
        }
        let defaultACL = try await ParseACL.setDefaultACL(ParseACL(),
                                                          withAccessForCurrentUser: true)

        let score = GameScore(points: 10)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()

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
        do {
            let saved = try await score.save()
            XCTAssert(saved.hasSameObjectId(as: scoreOnServer))
            guard let savedCreatedAt = saved.createdAt,
                let savedUpdatedAt = saved.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(savedCreatedAt, scoreOnServer.createdAt)
            XCTAssertEqual(savedUpdatedAt, scoreOnServer.createdAt)
            XCTAssertNotNil(saved.ACL)
            XCTAssertEqual(saved.ACL?.publicRead, defaultACL.publicRead)
            XCTAssertEqual(saved.ACL?.publicWrite, defaultACL.publicWrite)
            XCTAssertTrue(defaultACL.getReadAccess(objectId: userObjectId))
            XCTAssertTrue(defaultACL.getWriteAccess(objectId: userObjectId))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUpdate() async throws {
        var score = GameScore(points: 10)
        score.objectId = "yarr"
        score.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.ACL = nil

        var scoreOnServer = score
        scoreOnServer.updatedAt = Date()

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
        do {
            let saved = try await score.save()
            guard let savedUpdatedAt = saved.updatedAt else {
                XCTFail("Should unwrap dates")
                return
            }
            guard let originalUpdatedAt = score.updatedAt else {
                XCTFail("Should unwrap dates")
                return
            }
            XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(saved.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let saved = try await score.save(options: [.usePrimaryKey])
            guard let savedUpdatedAt = saved.updatedAt else {
                XCTFail("Should unwrap dates")
                return
            }
            guard let originalUpdatedAt = score.updatedAt else {
                XCTFail("Should unwrap dates")
                return
            }
            XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(saved.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUpdateWithDefaultACL() async throws {
        _ = try await loginNormally()
        _ = try await ParseACL.setDefaultACL(ParseACL(), withAccessForCurrentUser: true)

        var score = GameScore(points: 10)
        score.objectId = "yarr"
        score.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.ACL = nil

        var scoreOnServer = score
        scoreOnServer.updatedAt = Date()

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
        do {
            let saved = try await score.save()
            guard let savedUpdatedAt = saved.updatedAt else {
                XCTFail("Should unwrap dates")
                return
            }
            guard let originalUpdatedAt = score.updatedAt else {
                XCTFail("Should unwrap dates")
                return
            }
            XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(saved.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func saveAsync(score: GameScore, scoreOnServer: GameScore, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Save object1")

        score.save(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: scoreOnServer))
                guard let savedCreatedAt = saved.createdAt,
                    let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                }
                XCTAssertEqual(savedCreatedAt, scoreOnServer.createdAt)
                XCTAssertEqual(savedUpdatedAt, scoreOnServer.createdAt)
                XCTAssertEqual(saved.ACL, scoreOnServer.ACL)
                if callbackQueue.qos == .userInteractive {
                    XCTAssertTrue(Thread.isMainThread)
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "Save object2")
        score.save(options: [.usePrimaryKey], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: scoreOnServer))
                guard let savedCreatedAt = saved.createdAt,
                    let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation2.fulfill()
                        return
                }
                XCTAssertEqual(savedCreatedAt, scoreOnServer.createdAt)
                XCTAssertEqual(savedUpdatedAt, scoreOnServer.createdAt)
                XCTAssertEqual(saved.ACL, scoreOnServer.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func testThreadSafeSaveAsync() {
        let score = GameScore(points: 10)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(scoreOnServer)
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
            self.saveAsync(score: score, scoreOnServer: scoreOnServer, callbackQueue: .global(qos: .background))
        }
    }
    #endif

    func testSaveAsyncMainQueue() {
        let score = GameScore(points: 10)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.ACL = nil
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(scoreOnServer)
            // Get dates in correct format from ParseDecoding strategy
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        self.saveAsync(score: score, scoreOnServer: scoreOnServer, callbackQueue: .main)
    }

    func updateAsync(score: GameScore, scoreOnServer: GameScore, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Update object1")

        score.save(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                guard let savedUpdatedAt = saved.updatedAt else {
                    XCTFail("Should unwrap dates")
                    expectation1.fulfill()
                    return
                }
                guard let originalUpdatedAt = score.updatedAt else {
                    XCTFail("Should unwrap dates")
                    expectation1.fulfill()
                    return
                }
                XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(saved.ACL)
                if callbackQueue.qos == .userInteractive {
                    XCTAssertTrue(Thread.isMainThread)
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "Update object2")
        score.save(options: [.usePrimaryKey], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                guard let savedUpdatedAt = saved.updatedAt else {
                    XCTFail("Should unwrap dates")
                    expectation2.fulfill()
                    return
                }
                guard let originalUpdatedAt = score.updatedAt else {
                    XCTFail("Should unwrap dates")
                    expectation2.fulfill()
                    return
                }
                XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(saved.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func testThreadSafeUpdateAsync() {
        var score = GameScore(points: 10)
        score.objectId = "yarr"
        score.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.ACL = nil

        var scoreOnServer = score
        scoreOnServer.updatedAt = Date()
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(scoreOnServer)
            // Get dates in correct format from ParseDecoding strategy
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            let delay = MockURLResponse.addRandomDelay(2)
            return MockURLResponse(data: encoded, statusCode: 200, delay: delay)
        }

        DispatchQueue.concurrentPerform(iterations: 3) { _ in
            self.updateAsync(score: score, scoreOnServer: scoreOnServer, callbackQueue: .global(qos: .background))
        }
    }
    #endif

    func testUpdateAsyncMainQueue() {
        var score = GameScore(points: 10)
        score.objectId = "yarr"
        score.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.ACL = nil

        var scoreOnServer = score
        scoreOnServer.updatedAt = Date()
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(scoreOnServer)
            // Get dates in correct format from ParseDecoding strategy
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        self.updateAsync(score: score, scoreOnServer: scoreOnServer, callbackQueue: .main)
    }

    func testDeleteCommand() {
        var score = GameScore(points: 10)
        let className = score.className
        let objectId = "yarr"
        score.objectId = objectId
        do {
            let command = try score.deleteCommand()
            XCTAssertNotNil(command)
            XCTAssertEqual(command.path.urlComponent, "/classes/\(className)/\(objectId)")
            XCTAssertEqual(command.method, API.Method.DELETE)
            XCTAssertNil(command.body)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDelete() async throws {
        var score = GameScore(points: 10)
        let objectId = "yarr"
        score.objectId = objectId

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil
        let encoded: Data!
        do {
            encoded = try GameScore.getEncoder().encode(scoreOnServer, skipKeys: .none)
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
            try await score.delete(options: [])
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            try await score.delete(options: [.usePrimaryKey])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDeleteError() async throws {
        var score = GameScore(points: 10)
        let objectId = "yarr"
        score.objectId = objectId

        let parseError = ParseError(code: .objectNotFound, message: "Object not found")

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(parseError)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        do {
            try await score.delete(options: [])
            XCTFail("Should have thrown ParseError")
        } catch {
            if let error = error as? ParseError {
                XCTAssertEqual(error.code, parseError.code)
            } else {
                XCTFail("Should have thrown ParseError")
            }
        }

        do {
            try await score.delete(options: [.usePrimaryKey])
            XCTFail("Should have thrown ParseError")
        } catch {
            if let error = error as? ParseError {
                XCTAssertEqual(error.code, parseError.code)
            } else {
                XCTFail("Should have thrown ParseError")
            }
        }
    }

    func deleteAsync(score: GameScore, scoreOnServer: GameScore, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Delete object1")
        score.delete(options: [], callbackQueue: callbackQueue) { result in

            if case let .failure(error) = result {
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "Delete object2")
        score.delete(options: [.usePrimaryKey], callbackQueue: callbackQueue) { result in

            if case let .failure(error) = result {
                XCTFail(error.localizedDescription)
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func testThreadSafeDeleteAsync() {
        var score = GameScore(points: 10)
        let objectId = "yarr"
        score.objectId = objectId

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
            let delay = MockURLResponse.addRandomDelay(2)
            return MockURLResponse(data: encoded, statusCode: 200, delay: delay)
        }

        DispatchQueue.concurrentPerform(iterations: 3) { _ in
            self.deleteAsync(score: score, scoreOnServer: scoreOnServer, callbackQueue: .global(qos: .background))
        }
    }
    #endif

    func testDeleteAsyncMainQueue() {
        var score = GameScore(points: 10)
        let objectId = "yarr"
        score.objectId = objectId

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
        self.deleteAsync(score: score, scoreOnServer: scoreOnServer, callbackQueue: .main)
    }

    func deleteAsyncError(score: GameScore, parseError: ParseError, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Delete object1")
        score.delete(options: [], callbackQueue: callbackQueue) { result in

            if case let .failure(error) = result {
                XCTAssertEqual(error.code, parseError.code)
            } else {
                XCTFail("Should have thrown ParseError")
            }
            expectation1.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "Delete object2")
        score.delete(options: [.usePrimaryKey], callbackQueue: callbackQueue) { result in

            if case let .failure(error) = result {
                XCTAssertEqual(error.code, parseError.code)
            } else {
                XCTFail("Should have thrown ParseError")
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testDeleteAsyncMainQueueError() {
        var score = GameScore(points: 10)
        let objectId = "yarr"
        score.objectId = objectId

        let parseError = ParseError(code: .objectNotFound, message: "Object not found")
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(parseError)
        } catch {
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        self.deleteAsyncError(score: score, parseError: parseError, callbackQueue: .main)
    }

    func testDeepSaveOfUnsavedPointerArray() async throws {
        var score = GameScore(points: 10)
        let newLevel = Level()
        var newLevel2 = Level()
        newLevel2.name = "best"
        score.levels = [newLevel, newLevel]

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.ACL = nil
        scoreOnServer.objectId = "yarr"

        let encoded: Data!
        do {
            encoded = try scoreOnServer.getEncoder().encode(scoreOnServer, skipKeys: .none)
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded)
            XCTAssertEqual(scoreOnServer.levels?.count, score.levels?.count)
            XCTAssertEqual(scoreOnServer.levels?.first?.objectId, score.levels?.first?.objectId)
            XCTAssertEqual(scoreOnServer.levels?.last?.objectId, score.levels?.last?.objectId)
        } catch {
            XCTFail("Should have encoded/decoded")
            return
        }
    }

    func testDeepSavePointerArray() throws {
        var score = GameScore(points: 10)
        var level1 = Level()
        level1.objectId = "level1"
        var level2 = Level()
        level2.objectId = "level2"
        score.levels = [level1, level2]

        do {
            let encoded = try score.getEncoder().encode(score, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            guard let scoreOnServer = try (score.getDecoder()
                                            .decode([String: AnyCodable].self,
                                                    from: encoded))["levels"]?.value as? [[String: String]],
                  let first = scoreOnServer.first,
                  let second = scoreOnServer.last else {
                XCTFail("Should unwrapped decoded")
                return
            }
            XCTAssertEqual(first["__type"], "Pointer")
            XCTAssertEqual(first["objectId"], level1.objectId)
            XCTAssertEqual(first["className"], level1.className)
            XCTAssertEqual(second["__type"], "Pointer")
            XCTAssertEqual(second["objectId"], level2.objectId)
            XCTAssertEqual(second["className"], level2.className)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
    }
}

// swiftlint:disable:this file_length
