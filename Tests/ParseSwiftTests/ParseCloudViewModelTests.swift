//
//  ParseCloudViewModelTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/11/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(SwiftUI)
import Foundation
import XCTest
@testable import ParseSwift

class ParseCloudViewModelTests: XCTestCase {
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
        try await KeychainStore.shared.deleteAll()
        try await ParseStorage.shared.deleteAll()
    }

    func testFunction() {
        let response = AnyResultResponse<String>(result: "hello")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        let viewModel = Cloud(functionJobName: "test")
            .viewModel
        viewModel.error = ParseError(code: .otherCause, message: "error")
        viewModel.runFunction()

        let expectation = XCTestExpectation(description: "Run Function")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            XCTAssertEqual(viewModel.results, "hello")
            XCTAssertNil(viewModel.error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testFunctionError() {
        let response = ParseError(code: .otherCause, message: "Custom error")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        let viewModel = Cloud(functionJobName: "test")
            .viewModel
        viewModel.results = "Test"
        viewModel.runFunction()

        let expectation = XCTestExpectation(description: "Run Function")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            XCTAssertEqual(viewModel.results, nil)
            XCTAssertNotNil(viewModel.error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testJob() {
        let response = AnyResultResponse<String>(result: "hello")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        let viewModel = Cloud(functionJobName: "test")
            .viewModel
        viewModel.error = ParseError(code: .otherCause, message: "error")
        viewModel.startJob()

        let expectation = XCTestExpectation(description: "Start Job")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            XCTAssertEqual(viewModel.results, "hello")
            XCTAssertNil(viewModel.error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testViewModelStatic() {
        let response = AnyResultResponse<String>(result: "hello")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        let cloud = Cloud(functionJobName: "test")
        let viewModel = Cloud.viewModel(cloud)
        viewModel.error = ParseError(code: .otherCause, message: "error")
        viewModel.startJob()

        let expectation = XCTestExpectation(description: "Start Job")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            XCTAssertEqual(viewModel.results, "hello")
            XCTAssertNil(viewModel.error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testJobError() {
        let response = ParseError(code: .otherCause, message: "Custom error")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(response)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        let viewModel = Cloud(functionJobName: "test")
            .viewModel
        viewModel.results = "Test"
        viewModel.startJob()

        let expectation = XCTestExpectation(description: "Start Job")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            XCTAssertEqual(viewModel.results, nil)
            XCTAssertNotNil(viewModel.error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }
}
#endif
