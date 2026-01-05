//
//  ParseCloudableAsyncTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/28/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

class ParseCloudableAsyncTests: XCTestCase, @unchecked Sendable {
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
        #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        try KeychainStore.shared.deleteAll()
        #endif
        try await ParseStorage.shared.deleteAll()
    }

    @MainActor
    func testFunction() async throws {

        let response = AnyResultResponse<String?>(result: nil)
		let encoded = try ParseCoding.jsonEncoder().encode(response)
        MockURLProtocol.mockRequests { _ in
			MockURLResponse(data: encoded, statusCode: 200)
        }

        let cloud = Cloud(functionJobName: "test")
        let functionResponse = try await cloud.runFunction()
        XCTAssertNil(functionResponse)
    }

    @MainActor
    func testJob() async throws {

        let response = AnyResultResponse<String?>(result: nil)
		let encoded = try ParseCoding.jsonEncoder().encode(response)
        MockURLProtocol.mockRequests { _ in
			MockURLResponse(data: encoded, statusCode: 200)
        }

        let cloud = Cloud(functionJobName: "test")
        let functionResponse = try await cloud.startJob()
        XCTAssertNil(functionResponse)
    }
}
