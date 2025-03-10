//
//  ParseQueryTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 7/26/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseQueryTests: XCTestCase { // swiftlint:disable:this type_body_length

    enum QueryTestError: Error, CustomStringConvertible {

        case couldNotDecodeAsString

        var description: String {
            switch self {
            case .couldNotDecodeAsString:
                return "Could not decode to String"
            }
        }

    }

    struct GameScore: ParseObject, ParseQueryScorable {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var score: Double?
        var originalData: Data?

        //: Your own properties
        var points: Int
        var isCounts: Bool?

        //: a custom initializer
        init() {
            self.points = 5
        }
        init(points: Int) {
            self.points = points
        }
    }

    struct GameScoreBroken: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        var points: Int?
    }

    struct AnyResultsResponse<U: Codable>: Codable {
        let results: [U]
    }

    struct AnyResultsMongoResponse<U: Codable>: Codable {
        let results: U
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
                                        usingEqualQueryConstraint: false,
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

    func encodeDoubleAsString(_ double: Double) throws -> String {
        let encodedDouble = try ParseCoding.jsonEncoder().encode(double)
        let decodedDouble = String(decoding: encodedDouble, as: UTF8.self)
        return decodedDouble
    }

    // MARK: Initialization
    func testConstructors() {
        let query = Query<GameScore>()
        XCTAssertEqual(query.className, GameScore.className)
        XCTAssertEqual(query.`where`.constraints.values.count, 0)

        let query2 = GameScore.query()
        XCTAssertEqual(query2.className, GameScore.className)
        XCTAssertEqual(query2.className, query.className)
        XCTAssertEqual(query2.`where`.constraints.values.count, 0)

        let query3 = GameScore.query("points" > 100, "createdAt" > Date())
        XCTAssertEqual(query3.className, GameScore.className)
        XCTAssertEqual(query3.className, query.className)
        XCTAssertEqual(query3.`where`.constraints.values.count, 2)

        let query4 = GameScore.query(["points" > 100, "createdAt" > Date()])
        XCTAssertEqual(query4.className, GameScore.className)
        XCTAssertEqual(query4.className, query.className)
        XCTAssertEqual(query4.`where`.constraints.values.count, 2)

        let query5 = GameScore.query
        XCTAssertEqual(query5.className, GameScore.className)
        XCTAssertEqual(query5.className, query.className)
        XCTAssertEqual(query5.`where`.constraints.values.count, 0)
    }

    func testDecodingQueryArrays() throws {
        let query = GameScore.query
            .order([.ascending("points"), .descending("oldScore")])
            .exclude("hello", "world")
            .include("foo", "bar")
            .select("yolo", "nolo")
        // swiftlint:disable:next line_length
        guard let encoded1 = "{\"_method\":\"GET\",\"excludeKeys\":[\"hello\",\"world\"],\"include\":[\"foo\",\"bar\"],\"keys\":[\"yolo\",\"nolo\"],\"limit\":100,\"order\":[\"points\",\"-oldScore\"],\"skip\":0,\"where\":{}}".data(using: .utf8) else {
            XCTFail("Should have unwrapped")
            return
        }
        let decoded1 = try ParseCoding.jsonDecoder().decode(Query<GameScore>.self, from: encoded1)
        XCTAssertEqual(query, decoded1)
        // swiftlint:disable:next line_length
        guard let encoded2 = "{\"_method\":\"GET\",\"excludeKeys\":\"hello,world\",\"include\":\"foo,bar\",\"keys\":\"yolo,nolo\",\"limit\":100,\"order\":\"points,-oldScore\",\"skip\":0,\"where\":{}}".data(using: .utf8) else {
            XCTFail("Should have unwrapped")
            return
        }
        let decoded2 = try ParseCoding.jsonDecoder().decode(Query<GameScore>.self, from: encoded2)
        XCTAssertEqual(query, decoded2)
    }

    func testCompareQueries() {

        let query1 = GameScore.query("points" > 100, "createdAt" > Date())
        let query2 = GameScore.query([containsString(key: "hello",
                                                     substring: "world"),
                                      "points" > 100,
                                      "createdAt" > Date()])
        let query3 = GameScore.query([containsString(key: "hello",
                                                     substring: "world"),
                                      "points" > 101,
                                      "createdAt" > Date()])
        let query4 = GameScore.query([containsString(key: "hello",
                                                     substring: "world"),
                                      "points" > 101,
                                      "createdAt" > Date(),
                                      isNull(key: "points")])
        let query5 = GameScore.query(isNull(key: "points"))
        let query6 = GameScore.query(isNull(key: "hello"))
        XCTAssertEqual(query1, query1)
        XCTAssertEqual(query2, query2)
        XCTAssertNotEqual(query1, query2)
        XCTAssertNotEqual(query2, query3)
        XCTAssertNotEqual(query3, query4)
        XCTAssertEqual(query5, query5)
        XCTAssertNotEqual(query5, query6)
    }

    func testEndPoints() {
        let query = Query<GameScore>()
        let userQuery = Query<BaseParseUser>()
        let installationQuery = Query<BaseParseInstallation>()
        XCTAssertEqual(query.endpoint.urlComponent, "/classes/GameScore")
        XCTAssertEqual(userQuery.endpoint.urlComponent, "/users")
        XCTAssertEqual(installationQuery.endpoint.urlComponent, "/installations")
    }

    func testStaticProperties() {
        XCTAssertEqual(Query<GameScore>.className, GameScore.className)
    }

    func testSkip() {
        let query = GameScore.query
        XCTAssertEqual(query.skip, 0)
        let query2 = GameScore.query.skip(1)
        XCTAssertEqual(query2.skip, 1)
    }

    func testLimit() {
        var query = GameScore.query
        XCTAssertEqual(query.limit, 100)
        query = query.limit(10)
        XCTAssertEqual(query.limit, 10)
    }

    func testOrder() {
        let query = GameScore.query
        XCTAssertNil(query.order)
        let query2 = GameScore.query.order(.ascending("yolo"))
        XCTAssertNotNil(query2.order)
    }

    func testReadPreferences() {
        let query = GameScore.query
        XCTAssertNil(query.readPreference)
        XCTAssertNil(query.includeReadPreference)
        XCTAssertNil(query.subqueryReadPreference)
        let query2 = GameScore.query.readPreference("PRIMARY",
                                                      includeReadPreference: "SECONDARY",
                                                      subqueryReadPreference: "SECONDARY_PREFERRED")
        XCTAssertNotNil(query2.readPreference)
        XCTAssertNotNil(query2.includeReadPreference)
        XCTAssertNotNil(query2.subqueryReadPreference)
    }

    func testIncludeKeys() {
        let query = GameScore.query
        XCTAssertNil(query.include)
        var query2 = GameScore.query.include(["yolo"])
        XCTAssertEqual(query2.include?.count, 1)
        XCTAssertEqual(query2.include?.first, "yolo")
        query2 = query2.include(["hello", "wow"])
        XCTAssertEqual(query2.include?.count, 3)
        XCTAssertEqual(query2.include, Set(["yolo", "hello", "wow"]))
    }

    func testIncludeKeysVariadic() {
        let query = GameScore.query
        XCTAssertNil(query.include)
        var query2 = GameScore.query.include("yolo")
        XCTAssertEqual(query2.include?.count, 1)
        XCTAssertEqual(query2.include?.first, "yolo")
        query2 = query2.include("hello", "wow")
        XCTAssertEqual(query2.include?.count, 3)
        XCTAssertEqual(query2.include, Set(["yolo", "hello", "wow"]))
    }

    func testIncludeAllKeys() {
        let query = GameScore.query
        XCTAssertNil(query.include)
        let query2 = GameScore.query.includeAll()
        XCTAssertEqual(query2.include?.count, 1)
        XCTAssertEqual(query2.include, ["*"])
        let query3 = GameScore.query
            .include("hello")
            .includeAll()
        XCTAssertEqual(query3.include?.count, 2)
        XCTAssertEqual(query3.include, Set(["hello", "*"]))
    }

    func testExcludeKeys() throws {
        let query = GameScore.query
        XCTAssertNil(query.excludeKeys)
        var query2 = GameScore.query.exclude(["yolo"])
        XCTAssertEqual(query2.excludeKeys, ["yolo"])
        let encoded = try ParseCoding.jsonEncoder().encode(query2)
        let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
        guard let decodedKeys = decodedDictionary["excludeKeys"],
            let decodedValues = decodedKeys.value as? [String] else {
            XCTFail("Should have casted")
            return
        }
        XCTAssertEqual(decodedValues, ["yolo"])

        query2 = query2.exclude(["hello", "wow"])
        XCTAssertEqual(query2.excludeKeys, ["yolo", "hello", "wow"])
        let encoded2 = try ParseCoding.jsonEncoder().encode(query2)
        let decodedDictionary2 = try JSONDecoder().decode([String: AnyCodable].self, from: encoded2)
        guard let decodedKeys2 = decodedDictionary2["excludeKeys"],
            let decodedValues2 = decodedKeys2.value as? [String] else {
            XCTFail("Should have casted")
            return
        }
        XCTAssertEqual(Set(decodedValues2), Set(["yolo", "hello", "wow"]))
    }

    func testExcludeKeysVariadic() throws {
        let query = GameScore.query
        XCTAssertNil(query.excludeKeys)
        var query2 = GameScore.query.exclude("yolo")
        XCTAssertEqual(query2.excludeKeys, ["yolo"])
        let encoded = try ParseCoding.jsonEncoder().encode(query2)
        let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
        guard let decodedKeys = decodedDictionary["excludeKeys"],
            let decodedValues = decodedKeys.value as? [String] else {
            XCTFail("Should have casted")
            return
        }
        XCTAssertEqual(decodedValues, ["yolo"])

        query2 = query2.exclude("hello", "wow")
        XCTAssertEqual(query2.excludeKeys, ["yolo", "hello", "wow"])
        let encoded2 = try ParseCoding.jsonEncoder().encode(query2)
        let decodedDictionary2 = try JSONDecoder().decode([String: AnyCodable].self, from: encoded2)
        guard let decodedKeys2 = decodedDictionary2["excludeKeys"],
            let decodedValues2 = decodedKeys2.value as? [String] else {
            XCTFail("Should have casted")
            return
        }
        XCTAssertEqual(Set(decodedValues2), Set(["yolo", "hello", "wow"]))
    }

    func testSelectKeys() throws {
        let query = GameScore.query
        XCTAssertNil(query.keys)

        var query2 = GameScore.query.select(["yolo"])
        XCTAssertEqual(query2.keys?.count, 1)
        XCTAssertEqual(query2.keys?.first, "yolo")
        let encoded = try ParseCoding.jsonEncoder().encode(query2)
        let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
        guard let decodedKeys = decodedDictionary["keys"],
            let decodedValues = decodedKeys.value as? [String] else {
            XCTFail("Should have casted")
            return
        }
        XCTAssertEqual(decodedValues, ["yolo"])

        query2 = query2.select(["hello", "wow"])
        XCTAssertEqual(query2.keys?.count, 3)
        XCTAssertEqual(query2.keys, ["yolo", "hello", "wow"])
        let encoded2 = try ParseCoding.jsonEncoder().encode(query2)
        let decodedDictionary2 = try JSONDecoder().decode([String: AnyCodable].self, from: encoded2)
        guard let decodedKeys2 = decodedDictionary2["keys"],
            let decodedValues2 = decodedKeys2.value as? [String] else {
            XCTFail("Should have casted")
            return
        }
        XCTAssertEqual(Set(decodedValues2), Set(["yolo", "hello", "wow"]))
    }

    func testSelectKeysVariadic() throws {
        let query = GameScore.query
        XCTAssertNil(query.keys)

        var query2 = GameScore.query.select("yolo")
        XCTAssertEqual(query2.keys?.count, 1)
        XCTAssertEqual(query2.keys?.first, "yolo")
        let encoded = try ParseCoding.jsonEncoder().encode(query2)
        let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
        guard let decodedKeys = decodedDictionary["keys"],
            let decodedValues = decodedKeys.value as? [String] else {
            XCTFail("Should have casted")
            return
        }
        XCTAssertEqual(decodedValues, ["yolo"])

        query2 = query2.select("hello", "wow")
        XCTAssertEqual(query2.keys?.count, 3)
        XCTAssertEqual(query2.keys, ["yolo", "hello", "wow"])
        let encoded2 = try ParseCoding.jsonEncoder().encode(query2)
        let decodedDictionary2 = try JSONDecoder().decode([String: AnyCodable].self, from: encoded2)
        guard let decodedKeys2 = decodedDictionary2["keys"],
            let decodedValues2 = decodedKeys2.value as? [String] else {
            XCTFail("Should have casted")
            return
        }
        XCTAssertEqual(Set(decodedValues2), Set(["yolo", "hello", "wow"]))
    }

    func testEncodingSetParameters() throws {
        let query = GameScore.query
            .exclude("world", "hello")
            .include("foo", "bar")
            .select("yolo", "nolo")

        let encoded = try ParseCoding.jsonEncoder().encode(query)
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded,
                       // swiftlint:disable:next line_length
                       "{\"_method\":\"GET\",\"excludeKeys\":[\"hello\",\"world\"],\"include\":[\"bar\",\"foo\"],\"keys\":[\"nolo\",\"yolo\"],\"limit\":100,\"skip\":0,\"where\":{}}")
    }

    func testSortByTextScore() throws {
        let query = GameScore.query
        XCTAssertNil(query.keys)

        let expectedOrder = Query<GameScore>.Order.ascending("$score")
        var query2 = GameScore.query.sortByTextScore()
        XCTAssertEqual(query2.keys?.count, 1)
        XCTAssertEqual(query2.keys?.first, "$score")
        XCTAssertEqual(query2.order?.first, expectedOrder)
        let encoded = try ParseCoding.jsonEncoder().encode(query2)
        let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
        guard let decodedKeys = decodedDictionary["keys"],
            let decodedValues = decodedKeys.value as? [String],
            let decodedOrder = decodedDictionary["order"],
            let decodedOrderValue = decodedOrder.value as? [String] else {
            XCTFail("Should have casted")
            return
        }
        XCTAssertEqual(decodedValues, ["$score"])
        XCTAssertEqual(decodedOrderValue, ["$score"])

        query2 = query2.select(["hello", "wow"])
        XCTAssertEqual(query2.keys?.count, 3)
        XCTAssertEqual(query2.keys, ["$score", "hello", "wow"])
        let encoded2 = try ParseCoding.jsonEncoder().encode(query2)
        let decodedDictionary2 = try JSONDecoder().decode([String: AnyCodable].self, from: encoded2)
        guard let decodedKeys2 = decodedDictionary2["keys"],
            let decodedValues2 = decodedKeys2.value as? [String] else {
            XCTFail("Should have casted")
            return
        }
        XCTAssertEqual(Set(decodedValues2), Set(["$score", "hello", "wow"]))

        query2 = query2.sortByTextScore()
        XCTAssertEqual(query2.keys?.count, 3)
        XCTAssertEqual(query2.keys, ["$score", "hello", "wow"])
        let encoded3 = try ParseCoding.jsonEncoder().encode(query2)
        let decodedDictionary3 = try JSONDecoder().decode([String: AnyCodable].self, from: encoded3)
        guard let decodedKeys3 = decodedDictionary3["keys"],
            let decodedValues3 = decodedKeys3.value as? [String] else {
            XCTFail("Should have casted")
            return
        }
        XCTAssertEqual(Set(decodedValues3), Set(["$score", "hello", "wow"]))
    }

    func testAddingConstraints() {
        var query = GameScore.query
        XCTAssertEqual(query.className, GameScore.className)
        XCTAssertEqual(query.className, query.className)
        XCTAssertEqual(query.`where`.constraints.values.count, 0)

        query = query.`where`("points" > 100, "createdAt" > Date())
        XCTAssertEqual(query.`where`.constraints.values.count, 2)
    }

    func testFindCommand() async throws {
        let query = GameScore.query
        let command = try await query.findCommand()
        // swiftlint:disable:next line_length
        let expected = "{\"body\":{\"_method\":\"GET\",\"limit\":100,\"skip\":0,\"where\":{}},\"method\":\"POST\",\"path\":\"\\/classes\\/GameScore\"}"
        let encoded = try ParseCoding.jsonEncoder()
            .encode(command)
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testQueryEncoding() throws {
        let query = GameScore.query
        let expected = "{\"_method\":\"GET\",\"limit\":100,\"skip\":0,\"where\":{}}"
        XCTAssertEqual(query.debugDescription, expected)
        XCTAssertEqual(query.description, expected)
    }

    func testFindExplainCommand() async throws {
        let query = GameScore.query()
        let command: API.NonParseBodyCommand<Query<ParseQueryTests.GameScore>,
                                             [GameScore]> = try await query.findExplainCommand()
        // swiftlint:disable:next line_length
        let expected = "{\"body\":{\"_method\":\"GET\",\"explain\":true,\"limit\":100,\"skip\":0,\"where\":{}},\"method\":\"POST\",\"path\":\"\\/classes\\/GameScore\"}"
        let encoded = try ParseCoding.jsonEncoder()
            .encode(command)
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    // MARK: Querying Parse Server
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

        let query = GameScore.query()
        guard let score = try await query.find(options: []).first else {
            XCTFail("Should unwrap first object found")
            return
        }
        XCTAssert(score.hasSameObjectId(as: scoreOnServer))
    }

    func testFindLimit() async throws {
        let query = GameScore.query()
            .limit(0)
        let scores = try await query.find(options: [])
        XCTAssert(scores.isEmpty)
    }

    // MARK: Querying Parse Server
    func testFindEncoded() throws {

        let afterDate = Date().addingTimeInterval(-300)
        let query = GameScore.query("createdAt" > afterDate)
        let encodedJSON = try ParseCoding.jsonEncoder().encode(query)
        let decodedJSON = try ParseCoding.jsonDecoder().decode([String: AnyCodable].self, from: encodedJSON)
        let encodedParse = try ParseCoding.jsonEncoder().encode(query)
        let decodedParse = try ParseCoding.jsonDecoder().decode([String: AnyCodable].self, from: encodedParse)

        guard let jsonSkipAny = decodedJSON["skip"],
              let jsonSkip = jsonSkipAny.value as? Int,
              let jsonMethodAny = decodedJSON["_method"],
              let jsonMethod = jsonMethodAny.value as? String,
              let jsonLimitAny = decodedJSON["limit"],
              let jsonLimit = jsonLimitAny.value as? Int,
              let jsonWhereAny = decodedJSON["where"],
              let jsonWhere = jsonWhereAny.value as? [String: [String: [String: String]]] else {
            XCTFail("Should have casted all")
            return
        }

        guard let parseSkipAny = decodedParse["skip"],
              let parseSkip = parseSkipAny.value as? Int,
              let parseMethodAny = decodedParse["_method"],
              let parseMethod = parseMethodAny.value as? String,
              let parseLimitAny = decodedParse["limit"],
              let parseLimit = parseLimitAny.value as? Int,
              let parseWhereAny = decodedParse["where"],
              let parseWhere = parseWhereAny.value as? [String: [String: [String: String]]] else {
            XCTFail("Should have casted all")
            return
        }

        XCTAssertEqual(jsonSkip, parseSkip, "Parse should always match JSON")
        XCTAssertEqual(jsonMethod, parseMethod, "Parse should always match JSON")
        XCTAssertEqual(jsonLimit, parseLimit, "Parse should always match JSON")
        XCTAssertEqual(jsonWhere, parseWhere, "Parse should always match JSON")
    }

    func findAsync(scoreOnServer: GameScore, callbackQueue: DispatchQueue) {
        let query = GameScore.query()
        let expectation = XCTestExpectation(description: "Count object1")
        query.find(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let found):
                guard let score = found.first else {
                    XCTFail("Should unwrap score count")
                    expectation.fulfill()
                    return
                }
                XCTAssert(score.hasSameObjectId(as: scoreOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func testThreadSafeFindAsync() {
        var scoreOnServer = GameScore(points: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                let delay = MockURLResponse.addRandomDelay(2)
                return MockURLResponse(data: encoded, statusCode: 200, delay: delay)
            } catch {
                return nil
            }
        }

        DispatchQueue.concurrentPerform(iterations: 3) { _ in
            findAsync(scoreOnServer: scoreOnServer, callbackQueue: .global(qos: .background))
        }
    }
    #endif

    func testFindAsyncMainQueue() {
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
        findAsync(scoreOnServer: scoreOnServer, callbackQueue: .main)
    }

    func testFindLimitAsync() {
        let query = GameScore.query()
            .limit(0)
        let expectation = XCTestExpectation(description: "Count object1")
        query.find { results in
            switch results {

            case .success(let scores):
                XCTAssert(scores.isEmpty)
            case .failure(let error):
                XCTFail(error.description)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testFindAllAsync() {
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
        let query = GameScore.query()
        let expectation = XCTestExpectation(description: "Count object1")
        query.findAll { result in

            switch result {

            case .success(let found):
                guard let score = found.first else {
                    XCTFail("Should unwrap score count")
                    expectation.fulfill()
                    return
                }
                XCTAssert(score.hasSameObjectId(as: scoreOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            XCTAssertTrue(Thread.isMainThread)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testFindAllAsyncErrorSkip() {
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
        var query = GameScore.query()
        query.skip = 10
        let expectation = XCTestExpectation(description: "Count object1")
        query.findAll { result in

            switch result {

            case .success:
                XCTFail("Should have failed")
            case .failure(let error):
                XCTAssertTrue(error.message.contains("Cannot iterate"))
            }
            XCTAssertTrue(Thread.isMainThread)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testFindAllAsyncErrorOrder() {
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
        let query = GameScore.query()
            .order([.ascending("points")])
        let expectation = XCTestExpectation(description: "Count object1")
        query.findAll { result in

            switch result {

            case .success:
                XCTFail("Should have failed")
            case .failure(let error):
                XCTAssertTrue(error.message.contains("Cannot iterate"))
            }
            XCTAssertTrue(Thread.isMainThread)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testFindAllAsyncErrorLimit() {
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
        var query = GameScore.query()
        query.limit = 10
        let expectation = XCTestExpectation(description: "Count object1")
        query.findAll { result in

            switch result {

            case .success:
                XCTFail("Should have failed")
            case .failure(let error):
                XCTAssertTrue(error.message.contains("Cannot iterate"))
            }
            XCTAssertTrue(Thread.isMainThread)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testFindAllLimit() {
        let query = GameScore.query()
            .limit(0)
        let expectation = XCTestExpectation(description: "Count object1")
        query.findAll { results in
            switch results {

            case .success(let scores):
                XCTAssert(scores.isEmpty)
            case .failure(let error):
                XCTFail(error.description)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testFirstCommand() async throws {
        let query = GameScore.query()
        let command = try await query.firstCommand()
        // swiftlint:disable:next line_length
        let expected = "{\"body\":{\"_method\":\"GET\",\"limit\":1,\"skip\":0,\"where\":{}},\"method\":\"POST\",\"path\":\"\\/classes\\/GameScore\"}"
        let encoded = try ParseCoding.jsonEncoder()
            .encode(command)
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testFirstExplainCommand() async throws {
        let query = GameScore.query()
        let command: API.NonParseBodyCommand<Query<ParseQueryTests.GameScore>,
                                             GameScore> = try await query.firstExplainCommand()
        // swiftlint:disable:next line_length
        let expected = "{\"body\":{\"_method\":\"GET\",\"explain\":true,\"limit\":1,\"skip\":0,\"where\":{}},\"method\":\"POST\",\"path\":\"\\/classes\\/GameScore\"}"
        let encoded = try ParseCoding.jsonEncoder()
            .encode(command)
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
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

        let query = GameScore.query()
        let score = try await query.first(options: [])
        XCTAssert(score.hasSameObjectId(as: scoreOnServer))
    }

    func testFirstThrowDecodingError() async throws {
        var scoreOnServer = GameScoreBroken()
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScoreBroken>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let query = GameScore.query()
        do {
            _ = try await query.first(options: [])
            XCTFail("Should have thrown error")
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("Should have casted as ParseError")
                return
            }
            #if !os(Linux) && !os(Android) && !os(Windows)
            // swiftlint:disable:next line_length
            XCTAssertEqual(error.message, "Invalid struct: No value associated with key CodingKeys(stringValue: \"points\", intValue: nil) (\"points\").")
            XCTAssertEqual(error.code, .otherCause)
            #endif
        }
        do {
            _ = try await query.first(options: [])
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.containedIn([.otherCause]))
        }
    }

    func testFirstNoObjectFound() async throws {

        let results = QueryResponse<GameScore>(results: [GameScore](), count: 0)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let query = GameScore.query()
        do {
            _ = try await query.first(options: [])
            XCTFail("Should have thrown error")
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("Should have casted as ParseError")
                return
            }
            XCTAssertEqual(error.code, .objectNotFound)
        }
    }

    func testFirstLimit() async throws {
        let query = GameScore.query()
            .limit(0)
        do {
            _ = try await query.first()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.containedIn([.objectNotFound]))
        }
    }

    func firstAsyncNoObjectFound(scoreOnServer: GameScore, callbackQueue: DispatchQueue) {
        let query = GameScore.query()
        let expectation = XCTestExpectation(description: "Count object1")
        query.first(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success:
                XCTFail("Should have failed")

            case .failure(let error):
                XCTAssertEqual(error.code, .objectNotFound)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func firstAsync(scoreOnServer: GameScore, callbackQueue: DispatchQueue) {
        let query = GameScore.query()
        let expectation = XCTestExpectation(description: "Count object1")
        query.first(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let score):
                XCTAssert(score.hasSameObjectId(as: scoreOnServer))

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func testThreadSafeFirstAsync() {
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

        DispatchQueue.concurrentPerform(iterations: 1) { _ in
            firstAsync(scoreOnServer: scoreOnServer, callbackQueue: .global(qos: .background))
        }
    }
    #endif

    func testFirstAsyncMainQueue() {
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
        firstAsync(scoreOnServer: scoreOnServer, callbackQueue: .main)
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func testThreadSafeFirstAsyncNoObjectFound() {
        let scoreOnServer = GameScore(points: 10)
        let results = QueryResponse<GameScore>(results: [GameScore](), count: 0)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                let delay = MockURLResponse.addRandomDelay(2)
                return MockURLResponse(data: encoded, statusCode: 200, delay: delay)
            } catch {
                return nil
            }
        }

        DispatchQueue.concurrentPerform(iterations: 3) { _ in
            firstAsyncNoObjectFound(scoreOnServer: scoreOnServer, callbackQueue: .global(qos: .background))
        }
    }
    #endif

    func testFirstAsyncNoObjectFoundMainQueue() {
        let scoreOnServer = GameScore(points: 10)
        let results = QueryResponse<GameScore>(results: [GameScore](), count: 0)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        firstAsyncNoObjectFound(scoreOnServer: scoreOnServer, callbackQueue: .main)
    }

    func testFirstAsyncLimit() {
        let query = GameScore.query()
            .limit(0)
        let expectation = XCTestExpectation(description: "Find object1")
        query.first { results in
            switch results {

            case .success:
                XCTFail("Should have thrown error.")
            case .failure(let error):
                XCTAssertEqual(error.code, .objectNotFound)

            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testCountCommand() async throws {
        let query = GameScore.query()
        let command = try await query.countCommand()
        // swiftlint:disable:next line_length
        let expected = "{\"body\":{\"_method\":\"GET\",\"count\":true,\"limit\":0,\"skip\":0,\"where\":{}},\"method\":\"POST\",\"path\":\"\\/classes\\/GameScore\"}"
        let encoded = try ParseCoding.jsonEncoder()
            .encode(command)
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testCountExplainCommand() async throws {
        let query = GameScore.query()
        let command: API.NonParseBodyCommand<Query<ParseQueryTests.GameScore>,
                                             [Int]> = try await query.countExplainCommand()
        // swiftlint:disable:next line_length
        let expected = "{\"body\":{\"_method\":\"GET\",\"count\":true,\"explain\":true,\"limit\":1,\"skip\":0,\"where\":{}},\"method\":\"POST\",\"path\":\"\\/classes\\/GameScore\"}"
        let encoded = try ParseCoding.jsonEncoder()
            .encode(command)
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
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

        let query = GameScore.query()
        let scoreCount = try await query.count(options: [])
        XCTAssertEqual(scoreCount, 1)
    }

    func testCountLimit() async throws {
        let query = GameScore.query()
            .limit(0)
        let count = try await query.count()
        XCTAssertEqual(count, 0)
    }

    func countAsync(scoreOnServer: GameScore, callbackQueue: DispatchQueue) {
        let query = GameScore.query()
        let expectation = XCTestExpectation(description: "Count object1")
        query.count(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let scoreCount):
                XCTAssertEqual(scoreCount, 1)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func testThreadSafeCountAsync() {
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

        DispatchQueue.concurrentPerform(iterations: 1) { _ in
            countAsync(scoreOnServer: scoreOnServer, callbackQueue: .global(qos: .background))
        }
    }
    #endif

    func testCountAsyncMainQueue() {
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
        countAsync(scoreOnServer: scoreOnServer, callbackQueue: .main)
    }

    func testCountAsyncLimit() throws {
        let query = GameScore.query()
            .limit(0)
        let expectation = XCTestExpectation(description: "Count object1")
        query.count { result in
            switch result {

            case .success(let count):
                XCTAssertEqual(count, 0)
            case .failure(let error):
                XCTFail(error.description)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    // MARK: Standard Conditions
    func testWhereKeyExists() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$exists": true]
        ]
        let constraint = exists(key: "yolo")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Bool],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: Bool] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyDoesNotExist() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$exists": false]
        ]
        let constraint = doesNotExist(key: "yolo")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Bool],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: Bool] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyEqualToNoComparator() {
        let expected: [String: String] = [
            "yolo": "yarr"
        ]
        let query = GameScore.query(
            equalToNoComparator(
                key: "yolo",
                value: "yarr"
            )
        )
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decoded = try JSONDecoder().decode([String: String].self, from: encoded)

            XCTAssertEqual(expected, decoded)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyEqualToParseObjectError() throws {
        let compareObject = GameScore(points: 11)
        XCTAssertThrowsError(try GameScore.query("yolo" == compareObject))
    }

    func testWhereKeyEqualToBoolNoComparator() throws {
        let query = GameScore.query(
            equalToNoComparator(
                key: "isCounts",
                value: true
            )
        )
        let expected = "{\"_method\":\"GET\",\"limit\":100,\"skip\":0,\"where\":{\"isCounts\":true}}"
        XCTAssertEqual(query.debugDescription, expected)
        XCTAssertEqual(query.description, expected)
        let encoded = try ParseCoding.jsonEncoder().encode(query)
        let decoded = try ParseCoding.jsonDecoder().decode(Query<GameScore>.self, from: encoded)
        XCTAssertEqual(query, decoded)
    }

    func testWhereKeyEqualToBoolEQ() throws {
        let query = GameScore.query("isCounts" == true)
        let expected = "{\"_method\":\"GET\",\"limit\":100,\"skip\":0,\"where\":{\"isCounts\":{\"$eq\":true}}}"
        XCTAssertEqual(query.debugDescription, expected)
        XCTAssertEqual(query.description, expected)
        let encoded = try ParseCoding.jsonEncoder().encode(query)
        let decoded = try ParseCoding.jsonDecoder().decode(Query<GameScore>.self, from: encoded)
        XCTAssertEqual(query, decoded)
    }

    func testWhereKeyEqualToParseObjectNoComparator() throws {
        var compareObject = GameScore(points: 11)
        compareObject.objectId = "hello"
        let query = try GameScore.query(
            equalToNoComparator(
                key: "yolo",
                object: compareObject
            )
        )
        // swiftlint:disable:next line_length
        let expected = "{\"_method\":\"GET\",\"limit\":100,\"skip\":0,\"where\":{\"yolo\":{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"hello\"}}}"
        XCTAssertEqual(query.debugDescription, expected)
        let encoded = try ParseCoding.jsonEncoder().encode(query)
        let decoded = try ParseCoding.jsonDecoder().decode(Query<GameScore>.self, from: encoded)
        XCTAssertEqual(query, decoded)
    }

    func testWhereKeyEqualToParseObjectEQ() throws {
        var compareObject = GameScore(points: 11)
        compareObject.objectId = "hello"
        let query = try GameScore.query("yolo" == compareObject)
        // swiftlint:disable:next line_length
        let expected = "{\"_method\":\"GET\",\"limit\":100,\"skip\":0,\"where\":{\"yolo\":{\"$eq\":{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"hello\"}}}}"
        XCTAssertEqual(query.debugDescription, expected)
        let encoded = try ParseCoding.jsonEncoder().encode(query)
        let decoded = try ParseCoding.jsonDecoder().decode(Query<GameScore>.self, from: encoded)
        XCTAssertEqual(query, decoded)
    }

    func testWhereKeyEqualToParseObjectDuplicateConstraint() throws {
        var compareObject = GameScore(points: 11)
        compareObject.objectId = "hello"
        let query = try GameScore.query(
            "yolo" == compareObject,
            "yolo" == compareObject
        )
        // swiftlint:disable:next line_length
        let expected = "{\"_method\":\"GET\",\"limit\":100,\"skip\":0,\"where\":{\"yolo\":{\"$eq\":{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"hello\"}}}}"
        XCTAssertEqual(query.debugDescription, expected)
        let encoded = try ParseCoding.jsonEncoder().encode(query)
        let decoded = try ParseCoding.jsonDecoder().decode(Query<GameScore>.self, from: encoded)
        XCTAssertEqual(query, decoded)
    }

    func testWhereKeyEqualToParseObjectPointer() throws {
        var compareObject = GameScore(points: 11)
        compareObject.objectId = "hello"
        let pointer = try compareObject.toPointer()
        let query = GameScore.query("yolo" == pointer)
        // swiftlint:disable:next line_length
        let expected = "{\"_method\":\"GET\",\"limit\":100,\"skip\":0,\"where\":{\"yolo\":{\"$eq\":{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"hello\"}}}}"
        XCTAssertEqual(query.debugDescription, expected)
        let encoded = try ParseCoding.jsonEncoder().encode(query)
        let decoded = try ParseCoding.jsonDecoder().decode(Query<GameScore>.self, from: encoded)
        XCTAssertEqual(query, decoded)
    }

    func testWhereKeyNotEqualToParseObject() throws {
        var compareObject = GameScore(points: 11)
        compareObject.objectId = "hello"
        let query = try GameScore.query("yolo" != compareObject)
        // swiftlint:disable:next line_length
        let expected = "{\"_method\":\"GET\",\"limit\":100,\"skip\":0,\"where\":{\"yolo\":{\"$ne\":{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"hello\"}}}}"
        XCTAssertEqual(query.debugDescription, expected)
        let encoded = try ParseCoding.jsonEncoder().encode(query)
        let decoded = try ParseCoding.jsonDecoder().decode(Query<GameScore>.self, from: encoded)
        XCTAssertEqual(query, decoded)
    }

    func testWhereKeyIsNull() throws {
        var compareObject = GameScore(points: 11)
        compareObject.objectId = "hello"
        let query = GameScore.query(isNull(key: "yolo"))
            .order(.ascending("yolo"), .descending("points"))
        // swiftlint:disable:next line_length
        let expected = "{\"_method\":\"GET\",\"limit\":100,\"order\":[\"yolo\",\"-points\"],\"skip\":0,\"where\":{\"yolo\":null}}"
        XCTAssertEqual(query.debugDescription, expected)
        let encoded = try ParseCoding.jsonEncoder().encode(query)
        let decoded = try ParseCoding.jsonDecoder().decode(Query<GameScore>.self, from: encoded)
        XCTAssertEqual(query, decoded)
    }

    func testWhereKeyNotNull() throws {
        var compareObject = GameScore(points: 11)
        compareObject.objectId = "hello"
        let query = GameScore.query(isNotNull(key: "yolo"))
        let expected = "{\"_method\":\"GET\",\"limit\":100,\"skip\":0,\"where\":{\"yolo\":{\"$ne\":null}}}"
        XCTAssertEqual(query.debugDescription, expected)
        let encoded = try ParseCoding.jsonEncoder().encode(query)
        let decoded = try ParseCoding.jsonDecoder().decode(Query<GameScore>.self, from: encoded)
        XCTAssertEqual(query, decoded)
    }

    func testWhereKeyIsNullDuplicateConstraint() throws {
        var compareObject = GameScore(points: 11)
        compareObject.objectId = "hello"
        let query = GameScore.query(isNull(key: "yolo"),
                                    isNull(key: "yolo"))
        let expected = "{\"_method\":\"GET\",\"limit\":100,\"skip\":0,\"where\":{\"yolo\":null}}"
        XCTAssertEqual(query.debugDescription, expected)
        let encoded = try ParseCoding.jsonEncoder().encode(query)
        let decoded = try ParseCoding.jsonDecoder().decode(Query<GameScore>.self, from: encoded)
        XCTAssertEqual(query, decoded)
    }

    func testWhereKeyIsNullMultipleKey() throws {
        var compareObject = GameScore(points: 11)
        compareObject.objectId = "hello"
        let query = GameScore.query(isNull(key: "yolo"),
                                    isNull(key: "hello"))
        let expected = "{\"_method\":\"GET\",\"limit\":100,\"skip\":0,\"where\":{\"hello\":null,\"yolo\":null}}"
        XCTAssertEqual(query.debugDescription, expected)
        let encoded = try ParseCoding.jsonEncoder().encode(query)
        let decoded = try ParseCoding.jsonDecoder().decode(Query<GameScore>.self, from: encoded)
        XCTAssertEqual(query, decoded)
    }

    func testWhereKeyComparatorMultipleSameKey() throws {
        var compareObject = GameScore(points: 11)
        compareObject.objectId = "hello"
        let query = GameScore.query("yolo" >= 5,
                                    "yolo" <= 10)
        let expected = "{\"_method\":\"GET\",\"limit\":100,\"skip\":0,\"where\":{\"yolo\":{\"$gte\":5,\"$lte\":10}}}"
        XCTAssertEqual(query.debugDescription, expected)
        let encoded = try ParseCoding.jsonEncoder().encode(query)
        let decoded = try ParseCoding.jsonDecoder().decode(Query<GameScore>.self, from: encoded)
        XCTAssertEqual(query, decoded)
    }

    func testWhereKeyComparatorMultipleSameKeyDuplicate() throws {
        var compareObject = GameScore(points: 11)
        compareObject.objectId = "hello"
        let query = GameScore.query("yolo" >= 5,
                                    "yolo" >= 5,
                                    "yolo" <= 10)
        let expected = "{\"_method\":\"GET\",\"limit\":100,\"skip\":0,\"where\":{\"yolo\":{\"$gte\":5,\"$lte\":10}}}"
        XCTAssertEqual(query.debugDescription, expected)
        let encoded = try ParseCoding.jsonEncoder().encode(query)
        let decoded = try ParseCoding.jsonDecoder().decode(Query<GameScore>.self, from: encoded)
        XCTAssertEqual(query, decoded)
    }

    func testWhereKeyNotEqualTo() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$ne": "yarr"]
        ]
        let query = GameScore.query("yolo" != "yarr")
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyLessThan() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$lt": "yarr"]
        ]
        let query = GameScore.query("yolo" < "yarr")
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyLessThanOrEqualTo() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$lte": "yarr"]
        ]
        let query = GameScore.query("yolo" <= "yarr")
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyGreaterThan() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$gt": "yarr"]
        ]
        let query = GameScore.query("yolo" > "yarr")
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyGreaterThanOrEqualTo() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$gte": "yarr"]
        ]
        let query = GameScore.query("yolo" >= "yarr")
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyMatchesText() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$text": ["$search": ["$term": "yarr"]]]
        ]
        let constraint = matchesText(key: "yolo", text: "yarr")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: [String: String]]],
                  let decodedValues = decodedDictionary.values.first?.value as?
                    [String: [String: [String: String]]] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyMatchesTextNoOptions() throws {
        let expected: [String: AnyCodable] = [
            "yolo": ["$text": ["$search": ["$term": "yarr"]]]
        ]
        let constraint = try matchesText(key: "yolo", text: "yarr", options: [:])
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: [String: String]]],
                  let decodedValues = decodedDictionary.values.first?.value as?
                    [String: [String: [String: String]]] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyMatchesTextWithOptions() throws {
        let expected: [String: [String: [String: [String: AnyCodable]]]] = [
            "yolo": ["$text": ["$search": [
                "$term": "yarr",
                "$caseSensitive": true,
                "$diacriticSensitive": true
            ]]]
        ]
        let options: [ParseTextOption: Encodable] = [
            ParseTextOption.language: "brew",
            ParseTextOption.caseSensitive: true,
            ParseTextOption.diacriticSensitive: true
        ]
        let constraint = try matchesText(key: "yolo", text: "yarr", options: options)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: [String: [String: [String: AnyCodable]]]].self,
                                                             from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected["yolo"]?["$text"]?["$search"],
                  let expectedTerm = expectedValues["$term"]?.value as? String,
                  let expectedCaseSensitive = expectedValues["$caseSensitive"]?.value as? Bool,
                  let expectedDiacriticSensitive = expectedValues["$diacriticSensitive"]?.value as? Bool,
                  let decodedValues = decodedDictionary["yolo"]?["$text"]?["$search"],
                  let decodedTerm = decodedValues["$term"]?.value as? String,
                  let decodedCaseSensitive = decodedValues["$caseSensitive"]?.value as? Bool,
                  let decodedDiacriticSensitive = decodedValues["$diacriticSensitive"]?.value as? Bool else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedTerm, decodedTerm)
            XCTAssertEqual(expectedCaseSensitive, decodedCaseSensitive)
            XCTAssertEqual(expectedDiacriticSensitive, decodedDiacriticSensitive)
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyMatchesTextBadOptions() throws {
        XCTAssertThrowsError(try matchesText(key: "yolo", text: "yarr", options: [.language: true]))
        XCTAssertThrowsError(try matchesText(key: "yolo", text: "yarr", options: [.caseSensitive: "yolo"]))
        XCTAssertThrowsError(try matchesText(key: "yolo", text: "yarr", options: [.diacriticSensitive: "yolo"]))
    }

    func testWhereKeyMatchesRegex() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$regex": "yarr"]
        ]
        let constraint = matchesRegex(key: "yolo", regex: "yarr")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyMatchesRegexModifiers() {
        let expected: [String: AnyCodable] = [
            "yolo": [
                "$regex": "yarr",
                "$options": "i"
            ]
        ]
        let constraint = matchesRegex(key: "yolo", regex: "yarr", modifiers: "i")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyContainsString() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$regex": "\\Qyarr\\E"]
        ]
        let constraint = containsString(key: "yolo", substring: "yarr")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyContainsStringModifier() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$regex": "\\Qyarr\\E",
                     "$options": "i"]
        ]
        let constraint = containsString(key: "yolo", substring: "yarr", modifiers: "i")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyHasPrefix() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$regex": "^\\Qyarr\\E"]
        ]
        let constraint = hasPrefix(key: "yolo", prefix: "yarr")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyHasPrefixModifier() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$regex": "^\\Qyarr\\E",
                     "$options": "i"]
        ]
        let constraint = hasPrefix(key: "yolo", prefix: "yarr", modifiers: "i")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyHasSuffix() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$regex": "\\Qyarr\\E$"]
        ]
        let constraint = hasSuffix(key: "yolo", suffix: "yarr")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyHasSuffixModifier() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$regex": "\\Qyarr\\E$",
                     "$options": "i"]
        ]
        let constraint = hasSuffix(key: "yolo", suffix: "yarr", modifiers: "i")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testOrQuery() {
        let expected: [String: AnyCodable] = [
            "$or": [
                ["points": ["$lte": 50]],
                ["points": ["$lte": 200]]
            ]
        ]
        let query1 = GameScore.query("points" <= 50)
        let query2 = GameScore.query("points" <= 200)
        let constraint = or(queries: query1, query2)
        let query = Query<GameScore>(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [[String: [String: Int]]],
                  let decodedValues = decodedDictionary.values.first?.value as? [[String: [String: Int]]] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testNorQuery() {
        let expected: [String: AnyCodable] = [
            "$nor": [
                ["points": ["$lte": 50]],
                ["points": ["$lte": 200]]
            ]
        ]
        let query1 = GameScore.query("points" <= 50)
        let query2 = GameScore.query("points" <= 200)
        let constraint = nor(queries: query1, query2)
        let query = Query<GameScore>(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [[String: [String: Int]]],
                  let decodedValues = decodedDictionary.values.first?.value as? [[String: [String: Int]]] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testAndQuery() {
        let expected: [String: AnyCodable] = [
            "$and": [
                ["points": ["$lte": 50]],
                ["points": ["$lte": 200]]
            ]
        ]
        let query1 = GameScore.query("points" <= 50)
        let query2 = GameScore.query("points" <= 200)
        let constraint = and(queries: query1, query2)
        let query = Query<GameScore>(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [[String: [String: Int]]],
                  let decodedValues = decodedDictionary.values.first?.value as? [[String: [String: Int]]] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyMatchesKeyInQuery() {
        let expected: [String: AnyCodable] = [
            "yolo": [
                "$select": [
                    "query": ["where": ["test": ["$lte": "awk"]]],
                    "key": "yolo1"
                ] as [String: Any]
            ]
        ]
        let inQuery = GameScore.query("test" <= "awk")
        let constraint = matchesKeyInQuery(key: "yolo", queryKey: "yolo1", query: inQuery)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: Any]],
                  let expectedSelect = expectedValues["$select"],
                  let expectedKeyValue = expectedSelect["key"] as? String,
                  let expectedKeyQuery = expectedSelect["query"] as? [String: Any],
                  let expectedKeyWhere = expectedKeyQuery["where"] as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: [String: Any]],
                  let decodedSelect = decodedValues["$select"],
                  let decodedKeyValue = decodedSelect["key"] as? String,
                  let decodedKeyQuery = decodedSelect["query"] as? [String: Any],
                  let decodedKeyWhere = decodedKeyQuery["where"] as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            XCTAssertEqual(expectedKeyValue, decodedKeyValue)
            XCTAssertEqual(expectedKeyWhere, decodedKeyWhere)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyDoesNotMatchKeyInQuery() {
        let expected: [String: AnyCodable] = [
            "yolo": [
                "$dontSelect": [
                    "query": ["where": ["test": ["$lte": "awk"]]],
                    "key": "yolo1"
                ] as [String: Any]
            ]
        ]
        let inQuery = GameScore.query("test" <= "awk")
        let constraint = doesNotMatchKeyInQuery(key: "yolo", queryKey: "yolo1", query: inQuery)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: Any]],
                  let expectedSelect = expectedValues["$dontSelect"],
                  let expectedKeyValue = expectedSelect["key"] as? String,
                  let expectedKeyQuery = expectedSelect["query"] as? [String: Any],
                  let expectedKeyWhere = expectedKeyQuery["where"] as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: [String: Any]],
                  let decodedSelect = decodedValues["$dontSelect"],
                  let decodedKeyValue = decodedSelect["key"] as? String,
                  let decodedKeyQuery = decodedSelect["query"] as? [String: Any],
                  let decodedKeyWhere = decodedKeyQuery["where"] as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            XCTAssertEqual(expectedKeyValue, decodedKeyValue)
            XCTAssertEqual(expectedKeyWhere, decodedKeyWhere)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyMatchesQuery() {
        let expected: [String: AnyCodable] = [
            "yolo": [
                "$inQuery": [
                    "where": ["test": ["$lte": "awk"]]
                ]
            ]
        ]
        let inQuery = GameScore.query("test" <= "awk")
        let query = GameScore.query("yolo" == inQuery)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: Any]],
                  let expectedInQuery = expectedValues["$inQuery"],
                  let expectedKeyWhere = expectedInQuery["where"] as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: [String: Any]],
                  let decodedInQuery = decodedValues["$inQuery"],
                  let decodedKeyWhere = decodedInQuery["where"] as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            XCTAssertEqual(expectedKeyWhere, decodedKeyWhere)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyDoesNotMatchQuery() {
        let expected: [String: AnyCodable] = [
            "yolo": [
                "$notInQuery": [
                    "where": ["test": ["$lte": "awk"]]
                ]
            ]
        ]
        let inQuery = GameScore.query("test" <= "awk")
        let query = GameScore.query("yolo" != inQuery)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: Any]],
                  let expectedInQuery = expectedValues["$notInQuery"],
                  let expectedKeyWhere = expectedInQuery["where"] as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: [String: Any]],
                  let decodedInQuery = decodedValues["$notInQuery"],
                  let decodedKeyWhere = decodedInQuery["where"] as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            XCTAssertEqual(expectedKeyWhere, decodedKeyWhere)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereContainedIn() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$in": ["yarr"]]
        ]
        let constraint = containedIn(key: "yolo", array: ["yarr"])
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String]],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: [String]] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereContainedInParseObject() throws {
        var compareObject = GameScore(points: 11)
        compareObject.objectId = "hello"
        // swiftlint:disable:next line_length
        let expected = "{\"yolo\":{\"$in\":[{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"hello\"}]}}"
        let constraint = try containedIn(key: "yolo", array: [compareObject])
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decoded = String(decoding: encoded, as: UTF8.self)
            XCTAssertEqual(expected, decoded)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereNotContainedInParseObject() throws {
        var compareObject = GameScore(points: 11)
        compareObject.objectId = "hello"
        // swiftlint:disable:next line_length
        let expected = "{\"yolo\":{\"$nin\":[{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"hello\"}]}}"
        let constraint = try notContainedIn(key: "yolo", array: [compareObject])
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decoded = String(decoding: encoded, as: UTF8.self)
            XCTAssertEqual(expected, decoded)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereContainedByParseObject() throws {
        var compareObject = GameScore(points: 11)
        compareObject.objectId = "hello"
        // swiftlint:disable:next line_length
        let expected = "{\"yolo\":{\"$containedBy\":[{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"hello\"}]}}"
        let constraint = try containedBy(key: "yolo", array: [compareObject])
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decoded = String(decoding: encoded, as: UTF8.self)
            XCTAssertEqual(expected, decoded)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereContainsAllParseObject() throws {
        var compareObject = GameScore(points: 11)
        compareObject.objectId = "hello"
        // swiftlint:disable:next line_length
        let expected = "{\"yolo\":{\"$all\":[{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"hello\"}]}}"
        let constraint = try containsAll(key: "yolo", array: [compareObject])
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decoded = String(decoding: encoded, as: UTF8.self)
            XCTAssertEqual(expected, decoded)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereContainedBy() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$containedBy": ["yarr"]]
        ]
        let constraint = containedBy(key: "yolo", array: ["yarr"])
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String]],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: [String]] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereNotContainedIn() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$nin": ["yarr"]]
        ]
        let constraint = notContainedIn(key: "yolo", array: ["yarr"])
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String]],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: [String]] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereContainsAll() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$all": ["yarr"]]
        ]
        let constraint = containsAll(key: "yolo", array: ["yarr"])
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String]],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: [String]] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyRelated() throws {
        let expected: [String: AnyCodable] = [
            "$relatedTo": [
                "key": "yolo",
                "object": ["__type": "Pointer",
                           "className": "GameScore",
                           "objectId": "hello"]
            ]
        ]
        var object = GameScore(points: 50)
        object.objectId = "hello"
        let constraint = try related(key: "yolo", object: object)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Any],
                  let expectedKey = expectedValues["key"] as? String,
                  let expectedObject = expectedValues["object"] as? [String: String] else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: Any],
                  let decodedKey = decodedValues["key"] as? String,
                  let decodedObject = decodedValues["object"] as? [String: String] else {
                XCTFail("Should have casted")
                return
            }

            XCTAssertEqual(expectedKey, decodedKey)
            XCTAssertEqual(expectedObject, decodedObject)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyRelatedNoObject() throws {
        let expected: [String: AnyCodable] = [
            "$relatedTo": [
                "key": "yolo"
            ]
        ]
        var object = GameScore(points: 50)
        object.objectId = "hello"
        let constraint = related(key: "yolo")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Any],
                  let expectedKey = expectedValues["key"] as? String else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: Any],
                  let decodedKey = decodedValues["key"] as? String else {
                XCTFail("Should have casted")
                return
            }

            XCTAssertEqual(expectedKey, decodedKey)
            XCTAssertNil(decodedValues["object"])

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyRelatedPointer() throws {
        let expected: [String: AnyCodable] = [
            "$relatedTo": [
                "key": "yolo",
                "object": ["__type": "Pointer",
                           "className": "GameScore",
                           "objectId": "hello"]
            ]
        ]
        var object = GameScore(points: 50)
        object.objectId = "hello"
        let constraint = related(key: "yolo", object: try object.toPointer())
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Any],
                  let expectedKey = expectedValues["key"] as? String,
                  let expectedObject = expectedValues["object"] as? [String: String] else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: Any],
                  let decodedKey = decodedValues["key"] as? String,
                  let decodedObject = decodedValues["object"] as? [String: String] else {
                XCTFail("Should have casted")
                return
            }

            XCTAssertEqual(expectedKey, decodedKey)
            XCTAssertEqual(expectedObject, decodedObject)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyRelatedPointerNoKey() throws {
        let expected: [String: AnyCodable] = [
            "$relatedTo": [
                "object": ["__type": "Pointer",
                           "className": "GameScore",
                           "objectId": "hello"]
            ]
        ]
        var object = GameScore(points: 50)
        object.objectId = "hello"
        let constraint = related(object: try object.toPointer())
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Any],
                  let expectedObject = expectedValues["object"] as? [String: String] else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: Any],
                  let decodedObject = decodedValues["object"] as? [String: String] else {
                XCTFail("Should have casted")
                return
            }

            XCTAssertNil(decodedValues["key"])
            XCTAssertEqual(expectedObject, decodedObject)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyRelatedObject() throws {
        let expected: [String: AnyCodable] = [
            "$relatedTo": [
                "key": "yolo",
                "object": ["__type": "Pointer",
                           "className": "GameScore",
                           "objectId": "hello"]
            ]
        ]
        var object = GameScore(points: 50)
        object.objectId = "hello"
        let constraint = try related(key: "yolo", object: object)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Any],
                  let expectedKey = expectedValues["key"] as? String,
                  let expectedObject = expectedValues["object"] as? [String: String] else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: Any],
                  let decodedKey = decodedValues["key"] as? String,
                  let decodedObject = decodedValues["object"] as? [String: String] else {
                XCTFail("Should have casted")
                return
            }

            XCTAssertEqual(expectedKey, decodedKey)
            XCTAssertEqual(expectedObject, decodedObject)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyRelatedObjectNoKey() throws {
        let expected: [String: AnyCodable] = [
            "$relatedTo": [
                "object": ["__type": "Pointer",
                           "className": "GameScore",
                           "objectId": "hello"]
            ]
        ]
        var object = GameScore(points: 50)
        object.objectId = "hello"
        let constraint = try related(object: object)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Any],
                  let expectedObject = expectedValues["object"] as? [String: String] else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: Any],
                  let decodedObject = decodedValues["object"] as? [String: String] else {
                XCTFail("Should have casted")
                return
            }

            XCTAssertNil(decodedValues["key"])
            XCTAssertEqual(expectedObject, decodedObject)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyRelativeToTime() throws {
        let expected: [String: AnyCodable] = [
            "yolo": [
                "$gte": ["$relativeTime": "3 days ago"]
            ]
        ]
        var object = GameScore(points: 50)
        object.objectId = "hello"
        let constraint = relative("yolo" >= "3 days ago")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected
                    .values
                    .first?.value as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary
                    .values
                    .first?.value as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    // MARK: GeoPoint
    func testWhereKeyNearGeoPoint() throws {
        let expected: [String: AnyCodable] = [
            "yolo": ["$nearSphere": ["latitude": 10, "longitude": 20, "__type": "GeoPoint"] as [String: Any]]
        ]
        let geoPoint = try ParseGeoPoint(latitude: 10, longitude: 20)
        let constraint = near(key: "yolo", geoPoint: geoPoint)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: Any]],
                  let expectedLongitude = expectedValues["$nearSphere"]?["longitude"] as? Int,
                  let expectedLatitude = expectedValues["$nearSphere"]?["latitude"] as? Int,
                  let expectedType = expectedValues["$nearSphere"]?["__type"] as? String else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: [String: Any]],
                  let decodedLongitude = decodedValues["$nearSphere"]?["longitude"] as? Int,
                  let decodedLatitude = decodedValues["$nearSphere"]?["latitude"] as? Int,
                  let decodedType = decodedValues["$nearSphere"]?["__type"] as? String else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedLongitude, decodedLongitude)
            XCTAssertEqual(expectedLatitude, decodedLatitude)
            XCTAssertEqual(expectedType, decodedType)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyNearGeoPointWithinMiles() throws {
        let expected: [String: AnyCodable] = [
            "yolo": ["$nearSphere": ["latitude": 10, "longitude": 20, "__type": "GeoPoint"] as [String: Any],
                     "$maxDistance": 1
            ]
        ]
        let geoPoint = try ParseGeoPoint(latitude: 10, longitude: 20)
        let constraint = withinMiles(key: "yolo", geoPoint: geoPoint, distance: 3958.8)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Any],
                  let expectedNear = expectedValues["$nearSphere"] as? [String: Any],
                  let expectedLongitude = expectedNear["longitude"] as? Int,
                  let expectedLatitude = expectedNear["latitude"] as? Int,
                  let expectedType = expectedNear["__type"] as? String,
                  let expectedDistance = expectedValues["$maxDistance"] as? Int else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: Any],
                  let decodedNear = decodedValues["$nearSphere"] as? [String: Any],
                  let decodedLongitude = decodedNear["longitude"] as? Int,
                  let decodedLatitude = decodedNear["latitude"] as? Int,
                  let decodedType = decodedNear["__type"] as? String,
                  let decodedDistance = decodedValues["$maxDistance"] as? Int else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedLongitude, decodedLongitude)
            XCTAssertEqual(expectedLatitude, decodedLatitude)
            XCTAssertEqual(expectedType, decodedType)
            XCTAssertEqual(expectedDistance, decodedDistance)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyNearGeoPointWithinMilesNotSorted() throws {
        let expected: [String: AnyCodable] = [
            "yolo": ["$centerSphere": ["latitude": 10, "longitude": 20, "__type": "GeoPoint"] as [String: Any],
                     "$geoWithin": 1
            ]
        ]
        let geoPoint = try ParseGeoPoint(latitude: 10, longitude: 20)
        let constraint = withinMiles(key: "yolo",
                                     geoPoint: geoPoint,
                                     distance: 3958.8,
                                     sorted: false)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Any],
                  let expectedNear = expectedValues["$centerSphere"] as? [String: Any],
                  let expectedLongitude = expectedNear["longitude"] as? Int,
                  let expectedLatitude = expectedNear["latitude"] as? Int,
                  let expectedType = expectedNear["__type"] as? String,
                  let expectedDistance = expectedValues["$geoWithin"] as? Int else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: Any],
                  let decodedNear = decodedValues["$centerSphere"] as? [String: Any],
                  let decodedLongitude = decodedNear["longitude"] as? Int,
                  let decodedLatitude = decodedNear["latitude"] as? Int,
                  let decodedType = decodedNear["__type"] as? String,
                  let decodedDistance = decodedValues["$geoWithin"] as? Int else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedLongitude, decodedLongitude)
            XCTAssertEqual(expectedLatitude, decodedLatitude)
            XCTAssertEqual(expectedType, decodedType)
            XCTAssertEqual(expectedDistance, decodedDistance)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyNearGeoPointWithinKilometers() throws {
        let expected: [String: AnyCodable] = [
            "yolo": ["$nearSphere": ["latitude": 10, "longitude": 20, "__type": "GeoPoint"] as [String: Any],
                     "$maxDistance": 1
            ]
        ]
        let geoPoint = try ParseGeoPoint(latitude: 10, longitude: 20)
        let constraint = withinKilometers(key: "yolo", geoPoint: geoPoint, distance: 6371.0)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Any],
                  let expectedNear = expectedValues["$nearSphere"] as? [String: Any],
                  let expectedLongitude = expectedNear["longitude"] as? Int,
                  let expectedLatitude = expectedNear["latitude"] as? Int,
                  let expectedType = expectedNear["__type"] as? String,
                  let expectedDistance = expectedValues["$maxDistance"] as? Int else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: Any],
                  let decodedNear = decodedValues["$nearSphere"] as? [String: Any],
                  let decodedLongitude = decodedNear["longitude"] as? Int,
                  let decodedLatitude = decodedNear["latitude"] as? Int,
                  let decodedType = decodedNear["__type"] as? String,
                  let decodedDistance = decodedValues["$maxDistance"] as? Int else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedLongitude, decodedLongitude)
            XCTAssertEqual(expectedLatitude, decodedLatitude)
            XCTAssertEqual(expectedType, decodedType)
            XCTAssertEqual(expectedDistance, decodedDistance)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyNearGeoPointWithinKilometersNotSorted() throws {
        let expected: [String: AnyCodable] = [
            "yolo": ["$centerSphere": ["latitude": 10, "longitude": 20, "__type": "GeoPoint"] as [String: Any],
                     "$geoWithin": 1
            ]
        ]
        let geoPoint = try ParseGeoPoint(latitude: 10, longitude: 20)
        let constraint = withinKilometers(key: "yolo",
                                          geoPoint: geoPoint,
                                          distance: 6371.0,
                                          sorted: false)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Any],
                  let expectedNear = expectedValues["$centerSphere"] as? [String: Any],
                  let expectedLongitude = expectedNear["longitude"] as? Int,
                  let expectedLatitude = expectedNear["latitude"] as? Int,
                  let expectedType = expectedNear["__type"] as? String,
                  let expectedDistance = expectedValues["$geoWithin"] as? Int else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: Any],
                  let decodedNear = decodedValues["$centerSphere"] as? [String: Any],
                  let decodedLongitude = decodedNear["longitude"] as? Int,
                  let decodedLatitude = decodedNear["latitude"] as? Int,
                  let decodedType = decodedNear["__type"] as? String,
                  let decodedDistance = decodedValues["$geoWithin"] as? Int else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedLongitude, decodedLongitude)
            XCTAssertEqual(expectedLatitude, decodedLatitude)
            XCTAssertEqual(expectedType, decodedType)
            XCTAssertEqual(expectedDistance, decodedDistance)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyNearGeoPointWithinRadians() throws {
        let expected: [String: AnyCodable] = [
            "yolo": ["$nearSphere": ["latitude": 10, "longitude": 20, "__type": "GeoPoint"] as [String: Any],
                     "$maxDistance": 10
            ]
        ]
        let geoPoint = try ParseGeoPoint(latitude: 10, longitude: 20)
        let constraint = withinRadians(key: "yolo", geoPoint: geoPoint, distance: 10.0)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Any],
                  let expectedNear = expectedValues["$nearSphere"] as? [String: Any],
                  let expectedLongitude = expectedNear["longitude"] as? Int,
                  let expectedLatitude = expectedNear["latitude"] as? Int,
                  let expectedType = expectedNear["__type"] as? String,
                  let expectedDistance = expectedValues["$maxDistance"] as? Int else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: Any],
                  let decodedNear = decodedValues["$nearSphere"] as? [String: Any],
                  let decodedLongitude = decodedNear["longitude"] as? Int,
                  let decodedLatitude = decodedNear["latitude"] as? Int,
                  let decodedType = decodedNear["__type"] as? String,
                  let decodedDistance = decodedValues["$maxDistance"] as? Int else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedLongitude, decodedLongitude)
            XCTAssertEqual(expectedLatitude, decodedLatitude)
            XCTAssertEqual(expectedType, decodedType)
            XCTAssertEqual(expectedDistance, decodedDistance)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyNearGeoPointWithinRadiansNotSorted() throws {
        let expected: [String: AnyCodable] = [
            "yolo": ["$centerSphere": ["latitude": 10, "longitude": 20, "__type": "GeoPoint"] as [String: Any],
                     "$geoWithin": 10
            ]
        ]
        let geoPoint = try ParseGeoPoint(latitude: 10, longitude: 20)
        let constraint = withinRadians(key: "yolo", geoPoint: geoPoint, distance: 10.0, sorted: false)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Any],
                  let expectedNear = expectedValues["$centerSphere"] as? [String: Any],
                  let expectedLongitude = expectedNear["longitude"] as? Int,
                  let expectedLatitude = expectedNear["latitude"] as? Int,
                  let expectedType = expectedNear["__type"] as? String,
                  let expectedDistance = expectedValues["$geoWithin"] as? Int else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: Any],
                  let decodedNear = decodedValues["$centerSphere"] as? [String: Any],
                  let decodedLongitude = decodedNear["longitude"] as? Int,
                  let decodedLatitude = decodedNear["latitude"] as? Int,
                  let decodedType = decodedNear["__type"] as? String,
                  let decodedDistance = decodedValues["$geoWithin"] as? Int else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedLongitude, decodedLongitude)
            XCTAssertEqual(expectedLatitude, decodedLatitude)
            XCTAssertEqual(expectedType, decodedType)
            XCTAssertEqual(expectedDistance, decodedDistance)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyNearGeoBox() throws {
        let expected: [String: AnyCodable] = [
            "yolo": ["$within": ["$box": [
                ["latitude": 10, "longitude": 20, "__type": "GeoPoint"] as [String: Any],
                                    ["latitude": 20, "longitude": 30, "__type": "GeoPoint"]]
                                ]
            ]
        ]
        let geoPoint1 = try ParseGeoPoint(latitude: 10, longitude: 20)
        let geoPoint2 = try ParseGeoPoint(latitude: 20, longitude: 30)
        let constraint = withinGeoBox(key: "yolo", fromSouthWest: geoPoint1, toNortheast: geoPoint2)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: [[String: Any]]]],
                  let expectedBox = expectedValues["$within"]?["$box"],
                  let expectedLongitude = expectedBox.first?["longitude"] as? Int,
                  let expectedLatitude = expectedBox.first?["latitude"] as? Int,
                  let expectedType = expectedBox.first?["__type"] as? String,
                  let expectedLongitude2 = expectedBox.last?["longitude"] as? Int,
                  let expectedLatitude2 = expectedBox.last?["latitude"] as? Int,
                  let expectedType2 = expectedBox.last?["__type"] as? String else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: [String: [[String: Any]]]],
                  let decodedBox = decodedValues["$within"]?["$box"],
                  let decodedLongitude = decodedBox.first?["longitude"] as? Int,
                  let decodedLatitude = decodedBox.first?["latitude"] as? Int,
                  let decodedType = decodedBox.first?["__type"] as? String,
                  let decodedLongitude2 = decodedBox.last?["longitude"] as? Int,
                  let decodedLatitude2 = decodedBox.last?["latitude"] as? Int,
                  let decodedType2 = decodedBox.last?["__type"] as? String else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedLongitude, decodedLongitude)
            XCTAssertEqual(expectedLatitude, decodedLatitude)
            XCTAssertEqual(expectedType, decodedType)
            XCTAssertEqual(expectedLongitude2, decodedLongitude2)
            XCTAssertEqual(expectedLatitude2, decodedLatitude2)
            XCTAssertEqual(expectedType2, decodedType2)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func testWhereKeyWithinPolygonPoints() throws {
        let latitude1 = 10.1
        let longitude1 = 20.1
        let latitude2 = 20.1
        let longitude2 = 30.1
        let latitude3 = 30.1
        let longitude3 = 40.1
        // swiftlint:disable:next line_length
        let expected = "{\"yolo\":{\"$geoWithin\":{\"$polygon\":[{\"__type\":\"GeoPoint\",\"latitude\":\(try encodeDoubleAsString(latitude1)),\"longitude\":\(try encodeDoubleAsString(longitude1))},{\"__type\":\"GeoPoint\",\"latitude\":\(try encodeDoubleAsString(latitude2)),\"longitude\":\(try encodeDoubleAsString(longitude2))},{\"__type\":\"GeoPoint\",\"latitude\":\(try encodeDoubleAsString(latitude3)),\"longitude\":\(try encodeDoubleAsString(longitude3))}]}}}"
        let geoPoint1 = try ParseGeoPoint(latitude: latitude1, longitude: longitude1)
        let geoPoint2 = try ParseGeoPoint(latitude: latitude2, longitude: longitude2)
        let geoPoint3 = try ParseGeoPoint(latitude: latitude3, longitude: longitude3)
        let polygon = [geoPoint1, geoPoint2, geoPoint3]
        let constraint = withinPolygon(key: "yolo", points: polygon)
        let query = GameScore.query(constraint)
        XCTAssertEqual(query.where.description, expected)
    }

    func testWhereKeyWithinPolygon() throws {
        let latitude1 = 10.1
        let longitude1 = 20.1
        let latitude2 = 20.1
        let longitude2 = 30.1
        let latitude3 = 30.1
        let longitude3 = 40.1
        // swiftlint:disable:next line_length
        let expected = "{\"yolo\":{\"$geoWithin\":{\"$polygon\":{\"__type\":\"Polygon\",\"coordinates\":[[\(try encodeDoubleAsString(longitude1)),\(try encodeDoubleAsString(latitude1))],[\(try encodeDoubleAsString(longitude2)),\(try encodeDoubleAsString(latitude2))],[\(try encodeDoubleAsString(longitude3)),\(try encodeDoubleAsString(latitude3))]]}}}}"
        let geoPoint1 = try ParseGeoPoint(latitude: latitude1, longitude: longitude1)
        let geoPoint2 = try ParseGeoPoint(latitude: latitude2, longitude: longitude2)
        let geoPoint3 = try ParseGeoPoint(latitude: latitude3, longitude: longitude3)
        let polygon = try ParsePolygon(geoPoint1, geoPoint2, geoPoint3)
        let constraint = withinPolygon(key: "yolo", polygon: polygon)
        let query = GameScore.query(constraint)
        XCTAssertEqual(query.where.description, expected)
    }
    #endif

    func testWhereKeyPolygonContains() throws {
        let expected: [String: AnyCodable] = [
            "yolo": ["$geoIntersects": ["$point":
                                            ["latitude": 10, "longitude": 20, "__type": "GeoPoint"] as [String: Any]
                                ]
            ]
        ]
        let geoPoint = try ParseGeoPoint(latitude: 10, longitude: 20)
        let constraint = polygonContains(key: "yolo", point: geoPoint)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: [String: Any]]],
                  let expectedNear = expectedValues["$geoIntersects"]?["$point"],
                  let expectedLongitude = expectedNear["longitude"] as? Int,
                  let expectedLatitude = expectedNear["latitude"] as? Int,
                  let expectedType = expectedNear["__type"] as? String else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: [String: [String: Any]]],
                  let decodedNear = decodedValues["$geoIntersects"]?["$point"],
                  let decodedLongitude = decodedNear["longitude"] as? Int,
                  let decodedLatitude = decodedNear["latitude"] as? Int,
                  let decodedType = decodedNear["__type"] as? String else {
                XCTFail("Should have casted")
                return
            }

            XCTAssertEqual(expectedLongitude, decodedLongitude)
            XCTAssertEqual(expectedLatitude, decodedLatitude)
            XCTAssertEqual(expectedType, decodedType)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    // MARK: JSON Responses
    func testExplainFindSynchronous() async throws {
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

        let query = GameScore.query()
        let queryResult: [[String: String]] = try await query.findExplain()
        XCTAssertEqual(queryResult, json.results)
    }

    func testExplainMongoFindSynchronous() async throws {
        let json = AnyResultsMongoResponse(results: ["yolo": "yarr"])

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

        let query = GameScore.query()
        let queryResult: [[String: String]] = try await query.findExplain(usingMongoDB: true)
        XCTAssertEqual(queryResult, [json.results])
    }

    func testExplainFindLimitSynchronous() async throws {
        let query = GameScore.query()
            .limit(0)
        let queryResult: [[String: String]] = try await query.findExplain()
        XCTAssertTrue(queryResult.isEmpty)
    }

    func testExplainFindAsynchronous() {
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

        let expectation = XCTestExpectation(description: "Fetch object")
        let query = GameScore.query()
        query.findExplain(callbackQueue: .main) { (result: Result<[[String: String]], ParseError>) in
            switch result {

            case .success(let queryResult):
                XCTAssertEqual(queryResult, json.results)
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testExplainFindLimitAsynchronous() {

        let expectation = XCTestExpectation(description: "Fetch object")
        let query = GameScore.query()
            .limit(0)
        query.findExplain(callbackQueue: .main) { (result: Result<[[String: String]], ParseError>) in
            switch result {

            case .success(let queryResult):
                XCTAssertTrue(queryResult.isEmpty)
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testExplainFirstSynchronous() async throws {
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

        let query = GameScore.query()
        let queryResult: [String: String] = try await query.firstExplain()
        XCTAssertEqual(queryResult, json.results.first)
    }

    func testExplainMongoFirstSynchronous() async throws {
        let json = AnyResultsMongoResponse(results: ["yolo": "yarr"])

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

        let query = GameScore.query()
        let queryResult: [String: String] = try await query.firstExplain(usingMongoDB: true)
        XCTAssertEqual(queryResult, json.results)
    }

    func testExplainFirstLimitSynchronous() async throws {
        let query = GameScore.query()
            .limit(0)
        do {
            let _: [[String: String]] = try await query.firstExplain()
            XCTFail("Should have produced error")
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("Should have casted as ParseError")
                return
            }
            XCTAssertEqual(error.code, .objectNotFound)
        }
    }

    func testExplainFirstAsynchronous() {
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

        let expectation = XCTestExpectation(description: "Fetch object")
        let query = GameScore.query()
        query.firstExplain(callbackQueue: .main) { (result: Result<[String: String], ParseError>) in
            switch result {

            case .success(let queryResult):
                XCTAssertEqual(queryResult, json.results.first)
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testExplainFirstLimitAsynchronous() {

        let expectation = XCTestExpectation(description: "Fetch object")
        let query = GameScore.query()
            .limit(0)
        query.firstExplain(callbackQueue: .main) { (result: Result<[String: String], ParseError>) in
            switch result {

            case .success:
                XCTFail("Should have produced error")
            case .failure(let error):
                XCTAssertEqual(error.code, .objectNotFound)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testExplainCountSynchronous() async throws {
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

        let query = GameScore.query()
        let queryResult: [[String: String]] = try await query.countExplain()
        XCTAssertEqual(queryResult, json.results)
    }

    func testExplainMongoCountSynchronous() async throws {
        let json = AnyResultsMongoResponse(results: ["yolo": "yarr"])

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

        let query = GameScore.query()
        let queryResult: [[String: String]] = try await query.countExplain(usingMongoDB: true)
        XCTAssertEqual(queryResult, [json.results])
    }

    func testExplainCountLimitSynchronous() async throws {

        let query = GameScore.query()
            .limit(0)
        let queryResult: [[String: String]] = try await query.countExplain()
        XCTAssertTrue(queryResult.isEmpty)
    }

    func testExplainCountAsynchronous() {
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

        let expectation = XCTestExpectation(description: "Fetch object")
        let query = GameScore.query()
        query.countExplain(callbackQueue: .main) { (result: Result<[[String: String]], ParseError>) in
            switch result {

            case .success(let queryResult):
                XCTAssertEqual(queryResult, json.results)
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testExplainCountLimitAsynchronous() {

        let expectation = XCTestExpectation(description: "Fetch object")
        let query = GameScore.query()
            .limit(0)
        query.countExplain(callbackQueue: .main) { (result: Result<[[String: String]], ParseError>) in
            switch result {

            case .success(let queryResult):
                XCTAssertTrue(queryResult.isEmpty)
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testHintFindSynchronous() async throws {
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

        let query = GameScore.query()
            .hint("_id_")
        let queryResult: [[String: String]] = try await query.findExplain()
        XCTAssertEqual(queryResult, json.results)
    }

    func testHintFindAsynchronous() {
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

        let expectation = XCTestExpectation(description: "Fetch object")
        let query = GameScore.query()
            .hint("_id_")
        query.findExplain(callbackQueue: .main) { (result: Result<[[String: String]], ParseError>) in
            switch result {

            case .success(let queryResult):
                XCTAssertEqual(queryResult, json.results)
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testHintFirstSynchronous() async throws {
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

        let query = GameScore.query()
            .hint("_id_")
        let queryResult: [String: String] = try await query.firstExplain()
        XCTAssertEqual(queryResult, json.results.first)
    }

    func testHintFirstAsynchronous() {
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

        let expectation = XCTestExpectation(description: "Fetch object")
        let query = GameScore.query()
            .hint("_id_")
        query.firstExplain(callbackQueue: .main) { (result: Result<[String: String], ParseError>) in
            switch result {

            case .success(let queryResult):
                XCTAssertEqual(queryResult, json.results.first)
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testHintCountSynchronous() async throws {
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

        let query = GameScore.query()
            .hint("_id_")
        let queryResult: [[String: String]] = try await query.countExplain()
        XCTAssertEqual(queryResult, json.results)
    }

    func testHintCountAsynchronous() {
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

        let expectation = XCTestExpectation(description: "Fetch object")
        let query = GameScore.query()
            .hint("_id_")
        query.countExplain(callbackQueue: .main) { (result: Result<[[String: String]], ParseError>) in
            switch result {

            case .success(let queryResult):
                XCTAssertEqual(queryResult, json.results)
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testAggregateCommand() async throws {
        var query = GameScore.query()
        let value = AnyCodable("world")
        query.pipeline = [["hello": value]]
        let aggregate = try await query.aggregateCommand()
        // swiftlint:disable:next line_length
        let expected = "{\"body\":{\"pipeline\":[{\"hello\":\"\(value)\"}]},\"method\":\"POST\",\"path\":\"\\/aggregate\\/GameScore\"}"
        let encoded = try ParseCoding.jsonEncoder()
            .encode(aggregate)
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testAggregateExplainCommand() async throws {
        let query = GameScore.query()
        let command: API.NonParseBodyCommand<Query<GameScore>.AggregateBody<GameScore>,
                                             [String]> = try await query.aggregateExplainCommand()
        let expected = "{\"body\":{\"explain\":true},\"method\":\"POST\",\"path\":\"\\/aggregate\\/GameScore\"}"
        let encoded = try ParseCoding.jsonEncoder()
            .encode(command)
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testDistinctCommand() async throws {
        let query = GameScore.query()
        let aggregate = try await query.distinctCommand(key: "hello")
        let expected = "{\"body\":{\"distinct\":\"hello\"},\"method\":\"POST\",\"path\":\"\\/aggregate\\/GameScore\"}"
        let encoded = try ParseCoding.jsonEncoder()
            .encode(aggregate)
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testDistinctExplainCommand() async throws {
        let query = GameScore.query()
        let command: API.NonParseBodyCommand<Query<GameScore>.DistinctBody<GameScore>,
                                             [String]> = try await query.distinctExplainCommand(key: "hello")
        // swiftlint:disable:next line_length
        let expected = "{\"body\":{\"distinct\":\"hello\",\"explain\":true},\"method\":\"POST\",\"path\":\"\\/aggregate\\/GameScore\"}"
        let encoded = try ParseCoding.jsonEncoder()
            .encode(command)
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
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

        let query = GameScore.query()
        let pipeline = [["hello": "world"]]
        guard let score = try await query.aggregate(pipeline).first else {
            XCTFail("Should unwrap first object found")
            return
        }
        XCTAssert(score.hasSameObjectId(as: scoreOnServer))
    }

    func testAggregateWithWhere() async throws {
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

        let query = GameScore.query("points" > 9)
        let pipeline = [[String: String]]()
        guard let score = try await query.aggregate(pipeline).first else {
            XCTFail("Should unwrap first object found")
            return
        }
        XCTAssert(score.hasSameObjectId(as: scoreOnServer))
    }

    func testAggregateLimit() async throws {

        let query = GameScore.query()
            .limit(0)
        let pipeline = [["hello": "world"]]
        let scores = try await query.aggregate(pipeline)
        XCTAssertTrue(scores.isEmpty)
    }

    func testAggregateExplainWithWhere() async throws {
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

        let query = GameScore.query("points" > 9)
        let pipeline = [[String: String]]()
        guard let score: [String: String] = try await query.aggregateExplain(pipeline).first else {
            XCTFail("Should unwrap first object found")
            return
        }
        XCTAssertEqual(score, json.results.first)
    }

    func testAggregateExplainMongoWithWhere() async throws {
        let json = AnyResultsMongoResponse(results: ["yolo": "yarr"])

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

        let query = GameScore.query("points" > 9)
        let pipeline = [[String: String]]()
        guard let score: [String: String] = try await query.aggregateExplain(pipeline,
                                                                             usingMongoDB: true).first else {
            XCTFail("Should unwrap first object found")
            return
        }
        XCTAssertEqual(score, json.results)
    }

    func testAggregateExplainWithWhereLimit() async throws {

        let query = GameScore.query("points" > 9)
            .limit(0)
        let pipeline = [[String: String]]()
        let scores: [[String: String]] = try await query.aggregateExplain(pipeline)
        XCTAssertTrue(scores.isEmpty)
    }

    func testAggregateAsyncMainQueue() {
        var scoreOnServer = GameScore(points: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
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
        let query = GameScore.query()
        let expectation = XCTestExpectation(description: "Count object1")
        let pipeline = [[String: AnyEncodable]]()
        query.aggregate(pipeline, options: [], callbackQueue: .main) { result in

            switch result {

            case .success(let found):
                guard let score = found.first else {
                    XCTFail("Should unwrap score count")
                    expectation.fulfill()
                    return
                }
                XCTAssert(score.hasSameObjectId(as: scoreOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testAggregateWhereAsyncMainQueue() {
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
        let query = GameScore.query("points" > 9)
        let expectation = XCTestExpectation(description: "Aggregate object1")
        let pipeline = [[String: AnyEncodable]]()
        query.aggregate(pipeline, options: [], callbackQueue: .main) { result in

            switch result {

            case .success(let found):
                guard let score = found.first else {
                    XCTFail("Should unwrap score count")
                    expectation.fulfill()
                    return
                }
                XCTAssert(score.hasSameObjectId(as: scoreOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testAggregateAsyncMainQueueLimit() {

        let query = GameScore.query()
            .limit(0)
        let expectation = XCTestExpectation(description: "Count object1")
        let pipeline = [[String: AnyEncodable]]()
        query.aggregate(pipeline, options: [], callbackQueue: .main) { result in

            switch result {

            case .success(let found):
                XCTAssertTrue(found.isEmpty)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testAggregateExplainAsyncMainQueue() {
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
        let expectation = XCTestExpectation(description: "Aggregate object1")
        let pipeline = [[String: String]]()
        let query = GameScore.query("points" > 9)
        query.aggregateExplain(pipeline,
                               options: [],
                               callbackQueue: .main) { (result: Result<[[String: String]], ParseError>) in

            switch result {

            case .success(let found):
                guard let score = found.first else {
                    XCTFail("Should unwrap score count")
                    expectation.fulfill()
                    return
                }
                XCTAssertEqual(score, json.results.first)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testAggregateExplainAsyncMainQueueLimit() {

        let expectation = XCTestExpectation(description: "Aggregate object1")
        let pipeline = [[String: String]]()
        let query = GameScore.query("points" > 9)
            .limit(0)
        query.aggregateExplain(pipeline,
                               options: [],
                               callbackQueue: .main) { (result: Result<[[String: String]], ParseError>) in

            switch result {

            case .success(let found):
                XCTAssertTrue(found.isEmpty)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testDistinct() async throws {
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

        let query = GameScore.query("points" > 9)
        guard let score = try await query.distinct("hello").first else {
            XCTFail("Should unwrap first object found")
            return
        }
        XCTAssert(score.hasSameObjectId(as: scoreOnServer))
    }

    func testDistinctLimit() async throws {

        let query = GameScore.query("points" > 9)
            .limit(0)
        let scores = try await query.distinct("hello")
        XCTAssertTrue(scores.isEmpty)
    }

    func testDistinctExplain() async throws {
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

        let query = GameScore.query("points" > 9)
        guard let score: [String: String] = try await query.distinctExplain("hello").first else {
            XCTFail("Should unwrap first object found")
            return
        }
        XCTAssertEqual(score, json.results.first)
    }

    func testDistinctExplainMongo() async throws {
        let json = AnyResultsMongoResponse(results: ["yolo": "yarr"])

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

        let query = GameScore.query("points" > 9)
        guard let score: [String: String] = try await query.distinctExplain("hello",
                                                                            usingMongoDB: true).first else {
            XCTFail("Should unwrap first object found")
            return
        }
        XCTAssertEqual(score, json.results)
    }

    func testDistinctExplainLimit() async throws {

        let query = GameScore.query("points" > 9)
            .limit(0)
        let scores: [[String: String]] = try await query.distinctExplain("hello")
        XCTAssertTrue(scores.isEmpty)
    }

    func testDistinctAsyncMainQueue() {
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
        let query = GameScore.query("points" > 9)
        let expectation = XCTestExpectation(description: "Distinct object1")
        query.distinct("hello", options: [], callbackQueue: .main) { result in

            switch result {

            case .success(let found):
                guard let score = found.first else {
                    XCTFail("Should unwrap score count")
                    expectation.fulfill()
                    return
                }
                XCTAssert(score.hasSameObjectId(as: scoreOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testDistinctAsyncMainQueueLimit() {
        let query = GameScore.query("points" > 9)
            .limit(0)
        let expectation = XCTestExpectation(description: "Distinct object1")
        query.distinct("hello", options: [], callbackQueue: .main) { result in

            switch result {

            case .success(let found):
                XCTAssertTrue(found.isEmpty)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testDistinctExplainAsyncMainQueue() {
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
        let expectation = XCTestExpectation(description: "Aggregate object1")
        let query = GameScore.query("points" > 9)
        query.distinctExplain("hello",
                              options: [],
                              callbackQueue: .main) { (result: Result<[[String: String]], ParseError>) in

            switch result {

            case .success(let found):
                guard let score = found.first else {
                    XCTFail("Should unwrap score count")
                    expectation.fulfill()
                    return
                }
                XCTAssertEqual(score, json.results.first)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testDistinctExplainAsyncMainQueueLimit() {
        let expectation = XCTestExpectation(description: "Aggregate object1")
        let query = GameScore.query("points" > 9)
            .limit(0)
        query.distinctExplain("hello",
                              options: [],
                              callbackQueue: .main) { (result: Result<[[String: String]], ParseError>) in

            switch result {

            case .success(let found):
                XCTAssertTrue(found.isEmpty)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }
}
// swiftlint:disable:this file_length
