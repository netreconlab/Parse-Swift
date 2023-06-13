//
//  ParsePolygonTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/9/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import XCTest
@testable import ParseSwift

class ParsePolygonTests: XCTestCase {

    struct FakeParsePolygon: Encodable, Hashable {
        private let __type: String = "Polygon" // swiftlint:disable:this identifier_name
        public let coordinates: [[Double]]
    }

    var points = [ParseGeoPoint]()

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
        points = [
            try ParseGeoPoint(latitude: 0, longitude: 0),
            try ParseGeoPoint(latitude: 0, longitude: 1),
            try ParseGeoPoint(latitude: 1, longitude: 1),
            try ParseGeoPoint(latitude: 1, longitude: 0),
            try ParseGeoPoint(latitude: 0, longitude: 0)
        ]
    }

    override func tearDown() async throws {
        try await super.tearDown()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try await KeychainStore.shared.deleteAll()
        #endif
        try await ParseStorage.shared.deleteAll()
    }

    func testContainsPoint() throws {
        let polygon = try ParsePolygon(points)
        let inside = try ParseGeoPoint(latitude: 0.5, longitude: 0.5)
        let outside = try ParseGeoPoint(latitude: 10, longitude: 10)
        XCTAssertTrue(polygon.containsPoint(inside))
        XCTAssertFalse(polygon.containsPoint(outside))
    }

    func testContainsPoint2() throws {
        let point = try ParseGeoPoint(latitude: 40, longitude: -30)
        let points: [ParseGeoPoint] = [
            try .init(latitude: 35.0, longitude: -30.0),
            try .init(latitude: 42.0, longitude: -35.0),
            try .init(latitude: 42.0, longitude: -20.0)
        ]
        let polygon = try ParsePolygon(points)
        XCTAssertTrue(polygon.containsPoint(point))
    }

    func testCheckInitializerRequiresMinPoints() throws {
        let point = try ParseGeoPoint(latitude: 0, longitude: 0)
        XCTAssertNoThrow(try ParsePolygon([point, point, point]))
        XCTAssertThrowsError(try ParsePolygon([point, point]))
        XCTAssertNoThrow(try ParsePolygon(point, point, point))
        XCTAssertThrowsError(try ParsePolygon(point, point))
    }

    func testEncode() throws {
        let polygon = try ParsePolygon(points)
        let expected = "{\"__type\":\"Polygon\",\"coordinates\":[[0,0],[0,1],[1,1],[1,0],[0,0]]}"
        XCTAssertEqual(polygon.debugDescription, expected)
        guard polygon.coordinates.count == points.count else {
            XCTAssertEqual(polygon.coordinates.count, points.count)
            return
        }
        for (index, coordinates) in polygon.coordinates.enumerated() {
            XCTAssertEqual(coordinates, points[index])
        }
    }

    func testDecode() throws {
        var polygon = try ParsePolygon(points)
        polygon.isSwappingCoordinates = false
        let encoded = try ParseCoding.jsonEncoder().encode(polygon)
        let decoded = try ParseCoding.jsonDecoder().decode(ParsePolygon.self, from: encoded)
        XCTAssertEqual(decoded, polygon)
    }

    func testDecodeFailNotEnoughPoints() throws {
        let fakePolygon = FakeParsePolygon(coordinates: [[0.0, 0.0], [0.0, 1.0]])
        let encoded = try ParseCoding.jsonEncoder().encode(fakePolygon)
        do {
            _ = try ParseCoding.jsonDecoder().decode(ParsePolygon.self, from: encoded)
            XCTFail("Should have failed")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have unwrapped")
                return
            }
            XCTAssertTrue(parseError.message.contains("3 ParseGeoPoint"))
        }
    }

    func testDecodeFailWrongData() throws {
        let fakePolygon = FakeParsePolygon(coordinates: [[0.0], [1.0]])
        let encoded = try ParseCoding.jsonEncoder().encode(fakePolygon)
        do {
            _ = try ParseCoding.jsonDecoder().decode(ParsePolygon.self, from: encoded)
            XCTFail("Should have failed")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have unwrapped")
                return
            }
            XCTAssertTrue(parseError.message.contains("decode ParsePolygon"))
        }
    }

    func testDecodeFailTooMuchCoordinates() throws {
        let fakePolygon = FakeParsePolygon(coordinates: [[0.0, 0.0, 0.0], [0.0, 1.0, 1.0]])
        let encoded = try ParseCoding.jsonEncoder().encode(fakePolygon)
        do {
            _ = try ParseCoding.jsonDecoder().decode(ParsePolygon.self, from: encoded)
            XCTFail("Should have failed")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have unwrapped")
                return
            }
            XCTAssertTrue(parseError.message.contains("decode ParsePolygon"))
        }
    }

    func testDescription() throws {
        let polygon = try ParsePolygon(points)
        let expected = "{\"__type\":\"Polygon\",\"coordinates\":[[0,0],[0,1],[1,1],[1,0],[0,0]]}"
        XCTAssertEqual(polygon.description, expected)
    }
}
