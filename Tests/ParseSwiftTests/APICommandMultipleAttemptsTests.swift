//
//  APICommandMultipleAttemptsTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/11/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

// swiftlint:disable function_body_length

// swiftlint:disable:next type_body_length
class APICommandMultipleAttemptsTests: XCTestCase {
    struct Level: ParseObject {
        var objectId: String?

        var createdAt: Date?

        var updatedAt: Date?

        var ACL: ParseACL?

        var name = "First"

        var originalData: Data?
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              primaryKey: "primaryKey",
                              serverURL: url,
                              testing: true)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    actor Result: Sendable {
        var attempts = 0

        func incrementAttempts() {
            attempts += 1
        }
    }

    func testComputeDelayFromString() {
        let dateString = "Wed, 21 Oct 2015 07:28:00 GMT"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, d MMM yyyy HH:mm:ss z"
        guard let date = dateFormatter.date(from: dateString),
            let computedDate = URLSession.computeDelay(dateString) else {
            XCTFail("Should have produced date")
            return
        }
        XCTAssertLessThan(date.timeIntervalSinceNow - computedDate, 1)
    }

    func testErrorHTTP400JSON() throws {
        let parseError = ParseError(code: .connectionFailed, message: "Connection failed")
        let errorKey = "error"
        let errorValue = "yarr"
        let codeKey = "code"
        let codeValue = 100
        let responseDictionary: [String: Any] = [
            errorKey: errorValue,
            codeKey: codeValue
        ]
        Parse.configuration.maxConnectionAttempts = 2
        let currentAttempts = Result()

        MockURLProtocol.mockRequests { _ in
            do {
                let json = try JSONSerialization.data(withJSONObject: responseDictionary, options: [])
                return MockURLResponse(data: json, statusCode: 400, delay: 0.0)
            } catch {
                XCTFail(error.localizedDescription)
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Wait 1")

        API.NonParseBodyCommand<NoBody, NoBody>(method: .GET,
                                                path: .login,
                                                params: nil,
                                                mapper: { (_) -> NoBody in
            throw parseError
        }).executeAsync(options: [],
                        callbackQueue: .main,
                        allowIntermediateResponses: true) { result in
            switch result {
            case .success:
                XCTFail("Should have thrown an error")
                expectation1.fulfill()
            case .failure(let error):
                XCTAssertEqual(parseError.code, error.code)
                Task {
                    await currentAttempts.incrementAttempts()
                    let current = await currentAttempts.attempts
                    DispatchQueue.main.async {
                        if current >= Parse.configuration.maxConnectionAttempts {
                            expectation1.fulfill()
                        }
                    }
                }
            }
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testErrorHTTPReturns400NoDataFromServer() {
        Parse.configuration.maxConnectionAttempts = 2
        let originalError = ParseError(code: .otherCause, message: "Could not decode")
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(error: originalError) // Status code defaults to 400
        }
        let expectation1 = XCTestExpectation(description: "Wait")

        API.NonParseBodyCommand<NoBody, NoBody>(method: .GET,
                                                path: .login,
                                                params: nil,
                                                mapper: { (_) -> NoBody in
            throw originalError
        }).executeAsync(options: [],
                        callbackQueue: .main,
                        allowIntermediateResponses: true) { result in
            switch result {
            case .success:
                XCTFail("Should have thrown an error")
                expectation1.fulfill()
            case .failure(let error):
                XCTAssertEqual(originalError.code, error.code)
                expectation1.fulfill()
            }
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testErrorHTTP429JSONInterval() throws {
        let parseError = ParseError(code: .connectionFailed, message: "Connection failed")
        let errorKey = "error"
        let errorValue = "yarr"
        let codeKey = "code"
        let codeValue = 100
        let responseDictionary: [String: Any] = [
            errorKey: errorValue,
            codeKey: codeValue
        ]
        let headerKey = "x-rate-limit-reset"
        let headerValue = "2"
        let headerFields = [headerKey: headerValue]
        Parse.configuration.maxConnectionAttempts = 2
        let currentAttempts = Result()

        MockURLProtocol.mockRequests { _ in
            do {
                let json = try JSONSerialization.data(withJSONObject: responseDictionary, options: [])
                return MockURLResponse(data: json, statusCode: 429, delay: 0.0, headerFields: headerFields)
            } catch {
                XCTFail(error.localizedDescription)
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Wait")

        API.NonParseBodyCommand<NoBody, NoBody>(method: .GET,
                                                path: .login,
                                                params: nil,
                                                mapper: { (_) -> NoBody in
            throw parseError
        }).executeAsync(options: [],
                        callbackQueue: .main,
                        allowIntermediateResponses: true) { result in
            switch result {
            case .success:
                XCTFail("Should have thrown an error")
                expectation1.fulfill()
            case .failure(let error):
                XCTAssertEqual(parseError.code, error.code)
                Task {
                    await currentAttempts.incrementAttempts()
                    let current = await currentAttempts.attempts
                    DispatchQueue.main.async {
                        if current >= Parse.configuration.maxConnectionAttempts {
                            expectation1.fulfill()
                        }
                    }
                }
            }
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testErrorHTTP429JSONDate() throws {
        let parseError = ParseError(code: .connectionFailed, message: "Connection failed")
        let errorKey = "error"
        let errorValue = "yarr"
        let codeKey = "code"
        let codeValue = 100
        let responseDictionary: [String: Any] = [
            errorKey: errorValue,
            codeKey: codeValue
        ]
        let headerKey = "x-rate-limit-reset"
        guard let date = Calendar.current.date(byAdding: .second,
                                               value: 2,
                                               to: Date()) else {
            XCTFail("Should have produced date")
            return
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, d MMM yyyy HH:mm:ss z"
        let headerValue = dateFormatter.string(from: date)
        let headerFields = [headerKey: headerValue]
        Parse.configuration.maxConnectionAttempts = 2
        let currentAttempts = Result()

        MockURLProtocol.mockRequests { _ in
            do {
                let json = try JSONSerialization.data(withJSONObject: responseDictionary, options: [])
                return MockURLResponse(data: json, statusCode: 429, delay: 0.0, headerFields: headerFields)
            } catch {
                XCTFail(error.localizedDescription)
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Wait")

        API.NonParseBodyCommand<NoBody, NoBody>(method: .GET,
                                                path: .login,
                                                params: nil,
                                                mapper: { (_) -> NoBody in
            throw parseError
        }).executeAsync(options: [],
                        callbackQueue: .main,
                        allowIntermediateResponses: true) { result in
            switch result {
            case .success:
                XCTFail("Should have thrown an error")
                expectation1.fulfill()
            case .failure(let error):
                XCTAssertEqual(parseError.code, error.code)
                Task {
                    await currentAttempts.incrementAttempts()
                    let current = await currentAttempts.attempts
                    DispatchQueue.main.async {
                        if current >= Parse.configuration.maxConnectionAttempts {
                            expectation1.fulfill()
                        }
                    }
                }
            }
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testErrorHTTP429JSONNoHeader() throws {
        let parseError = ParseError(code: .connectionFailed, message: "Connection failed")
        let errorKey = "error"
        let errorValue = "yarr"
        let codeKey = "code"
        let codeValue = 100
        let responseDictionary: [String: Any] = [
            errorKey: errorValue,
            codeKey: codeValue
        ]
        Parse.configuration.maxConnectionAttempts = 2
        let currentAttempts = Result()

        MockURLProtocol.mockRequests { _ in
            do {
                let json = try JSONSerialization.data(withJSONObject: responseDictionary, options: [])
                return MockURLResponse(data: json, statusCode: 429, delay: 0.0)
            } catch {
                XCTFail(error.localizedDescription)
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Wait")

        API.NonParseBodyCommand<NoBody, NoBody>(method: .GET,
                                                path: .login,
                                                params: nil,
                                                mapper: { (_) -> NoBody in
            throw parseError
        }).executeAsync(options: [],
                        callbackQueue: .main,
                        allowIntermediateResponses: true) { result in
            switch result {
            case .success:
                XCTFail("Should have thrown an error")
                expectation1.fulfill()
            case .failure(let error):
                XCTAssertEqual(parseError.code, error.code)
                Task {
                    await currentAttempts.incrementAttempts()
                    let current = await currentAttempts.attempts
                    DispatchQueue.main.async {
                        if current >= Parse.configuration.maxConnectionAttempts {
                            expectation1.fulfill()
                        }
                    }
                }
            }
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testErrorHTTP503JSONInterval() throws {
        let parseError = ParseError(code: .connectionFailed, message: "Connection failed")
        let errorKey = "error"
        let errorValue = "yarr"
        let codeKey = "code"
        let codeValue = 100
        let responseDictionary: [String: Any] = [
            errorKey: errorValue,
            codeKey: codeValue
        ]
        let headerKey = "retry-after"
        let headerValue = "2"
        let headerFields = [headerKey: headerValue]
        Parse.configuration.maxConnectionAttempts = 2
        let currentAttempts = Result()

        MockURLProtocol.mockRequests { _ in
            do {
                let json = try JSONSerialization.data(withJSONObject: responseDictionary, options: [])
                return MockURLResponse(data: json, statusCode: 503, delay: 0.0, headerFields: headerFields)
            } catch {
                XCTFail(error.localizedDescription)
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Wait")

        API.NonParseBodyCommand<NoBody, NoBody>(method: .GET,
                                                path: .login,
                                                params: nil,
                                                mapper: { (_) -> NoBody in
            throw parseError
        }).executeAsync(options: [],
                        callbackQueue: .main,
                        allowIntermediateResponses: true) { result in
            switch result {
            case .success:
                XCTFail("Should have thrown an error")
                expectation1.fulfill()
            case .failure(let error):
                XCTAssertEqual(parseError.code, error.code)
                Task {
                    await currentAttempts.incrementAttempts()
                    let current = await currentAttempts.attempts
                    DispatchQueue.main.async {
                        if current >= Parse.configuration.maxConnectionAttempts {
                            expectation1.fulfill()
                        }
                    }
                }
            }
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testErrorHTTP503JSONDate() throws {
        let parseError = ParseError(code: .connectionFailed, message: "Connection failed")
        let errorKey = "error"
        let errorValue = "yarr"
        let codeKey = "code"
        let codeValue = 100
        let responseDictionary: [String: Any] = [
            errorKey: errorValue,
            codeKey: codeValue
        ]
        let headerKey = "retry-after"
        guard let date = Calendar.current.date(byAdding: .second,
                                               value: 2,
                                               to: Date()) else {
            XCTFail("Should have produced date")
            return
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, d MMM yyyy HH:mm:ss z"
        let headerValue = dateFormatter.string(from: date)
        let headerFields = [headerKey: headerValue]
        Parse.configuration.maxConnectionAttempts = 2
        let currentAttempts = Result()

        MockURLProtocol.mockRequests { _ in
            do {
                let json = try JSONSerialization.data(withJSONObject: responseDictionary, options: [])
                return MockURLResponse(data: json, statusCode: 503, delay: 0.0, headerFields: headerFields)
            } catch {
                XCTFail(error.localizedDescription)
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Wait")

        API.NonParseBodyCommand<NoBody, NoBody>(method: .GET,
                                                path: .login,
                                                params: nil,
                                                mapper: { (_) -> NoBody in
            throw parseError
        }).executeAsync(options: [],
                        callbackQueue: .main,
                        allowIntermediateResponses: true) { result in
            switch result {
            case .success:
                XCTFail("Should have thrown an error")
                expectation1.fulfill()
            case .failure(let error):
                XCTAssertEqual(parseError.code, error.code)
                Task {
                    await currentAttempts.incrementAttempts()
                    let current = await currentAttempts.attempts
                    DispatchQueue.main.async {
                        if current >= Parse.configuration.maxConnectionAttempts {
                            expectation1.fulfill()
                        }
                    }
                }
            }
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testErrorHTTP503JSONNoHeader() throws {
        let parseError = ParseError(code: .connectionFailed, message: "Connection failed")
        let errorKey = "error"
        let errorValue = "yarr"
        let codeKey = "code"
        let codeValue = 100
        let responseDictionary: [String: Any] = [
            errorKey: errorValue,
            codeKey: codeValue
        ]
        Parse.configuration.maxConnectionAttempts = 2
        let currentAttempts = Result()

        MockURLProtocol.mockRequests { _ in
            do {
                let json = try JSONSerialization.data(withJSONObject: responseDictionary, options: [])
                return MockURLResponse(data: json, statusCode: 503, delay: 0.0)
            } catch {
                XCTFail(error.localizedDescription)
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Wait")

        API.NonParseBodyCommand<NoBody, NoBody>(method: .GET,
                                                path: .login,
                                                params: nil,
                                                mapper: { (_) -> NoBody in
            throw parseError
        }).executeAsync(options: [],
                        callbackQueue: .main,
                        allowIntermediateResponses: true) { result in
            switch result {
            case .success:
                XCTFail("Should have thrown an error")
                expectation1.fulfill()
            case .failure(let error):
                XCTAssertEqual(parseError.code, error.code)
                Task {
                    await currentAttempts.incrementAttempts()
                    let current = await currentAttempts.attempts
                    DispatchQueue.main.async {
                        if current >= Parse.configuration.maxConnectionAttempts {
                            expectation1.fulfill()
                        }
                    }
                }
            }
        }
        wait(for: [expectation1], timeout: 20.0)
    }
}
#endif
