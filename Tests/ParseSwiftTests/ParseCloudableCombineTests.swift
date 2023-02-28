//
//  ParseCloudableCombineTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/30/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if canImport(Combine)

import Foundation
import XCTest
import Combine
@testable import ParseSwift

class ParseCloudableCombineTests: XCTestCase {

    struct Cloud: ParseCloudable {
        typealias ReturnType = String? // swiftlint:disable:this nesting

        // These are required by ParseObject
        var functionJobName: String
    }

    struct AnyResultResponse<U: Codable>: Codable {
        let result: U
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

    func testFunction() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        let response = AnyResultResponse<String?>(result: nil)

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let cloud = Cloud(functionJobName: "test")
        let publisher = cloud.runFunctionPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { functionResponse in

            XCTAssertNil(functionResponse)
        })
        publisher.store(in: &current)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testJob() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        let response = AnyResultResponse<String?>(result: nil)

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }

        let cloud = Cloud(functionJobName: "test")
        let publisher = cloud.startJobPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { functionResponse in

            XCTAssertNil(functionResponse)
        })
        publisher.store(in: &current)

        wait(for: [expectation1], timeout: 20.0)
    }
}

#endif
