//
//  ParseFileCombineTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/30/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine) && compiler(<6.0.0)

import Foundation
import XCTest
import Combine
@testable import ParseSwift

class ParseFileCombineTests: XCTestCase {

    let temporaryDirectory = "\(NSTemporaryDirectory())test/"

    struct FileUploadResponse: Codable {
        let name: String
        let url: URL
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
        guard let fileManager = ParseFileManager() else {
            throw ParseError(code: .otherCause, message: "Should have initialized file manage")
        }
        try fileManager.createDirectoryIfNeeded(temporaryDirectory)
    }

    override func tearDown() async throws {
        try await super.tearDown()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        try await KeychainStore.shared.deleteAll()
        #endif
        try await ParseStorage.shared.deleteAll()

        guard let fileManager = ParseFileManager() else {
            throw ParseError(code: .otherCause, message: "Should have initialized file manage")
        }
        let directory = URL(fileURLWithPath: temporaryDirectory, isDirectory: true)
        try? fileManager.removeDirectoryContents(directory)
        let directory2 = try ParseFileManager.downloadDirectory()
        try? fileManager.removeDirectoryContents(directory2)
    }

    func testFetch() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Fetch")

        // swiftlint:disable:next line_length
        guard let parseFileURL = URL(string: "http://localhost:1337/parse/files/applicationId/d3a37aed0672a024595b766f97133615_logo.svg") else {
            XCTFail("Should create URL")
            return
        }
        var parseFile = ParseFile(name: "d3a37aed0672a024595b766f97133615_logo.svg", cloudURL: parseFileURL)
        parseFile.url = parseFileURL

        let response = FileUploadResponse(name: "d3a37aed0672a024595b766f97133615_logo.svg",
                                          url: parseFileURL)
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(response)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = parseFile.fetchPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { fetched in

            XCTAssertEqual(fetched.name, response.name)
            XCTAssertEqual(fetched.url, response.url)
            XCTAssertNotNil(fetched.localURL)
        })
        publisher.store(in: &current)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testFetchFileProgress() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Fetch")

        // swiftlint:disable:next line_length
        guard let parseFileURL = URL(string: "http://localhost:1337/parse/files/applicationId/d3a37aed0672a024595b766f97133615_logo.svg") else {
            XCTFail("Should create URL")
            return
        }
        var parseFile = ParseFile(name: "d3a37aed0672a024595b766f97133615_logo.svg", cloudURL: parseFileURL)
        parseFile.url = parseFileURL

        let response = FileUploadResponse(name: "d3a37aed0672a024595b766f97133615_logo.svg",
                                          url: parseFileURL)
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(response)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = parseFile.fetchPublisher(progress: { (_, _, totalDownloaded, totalExpected) in
            let currentProgess = Double(totalDownloaded)/Double(totalExpected) * 100
            XCTAssertGreaterThan(currentProgess, -1)
        }).sink(receiveCompletion: { result in

            if case let .failure(error) = result {
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()

        }, receiveValue: { fetched in

            XCTAssertEqual(fetched.name, response.name)
            XCTAssertEqual(fetched.url, response.url)
            XCTAssertNotNil(fetched.localURL)
        })
        publisher.store(in: &current)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testSave() throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Fetch")

        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
        }
        let parseFile = ParseFile(name: "sampleData.txt", data: sampleData)

        // swiftlint:disable:next line_length
        guard let url = URL(string: "http://localhost:1337/parse/files/applicationId/89d74fcfa4faa5561799e5076593f67c_sampleData.txt") else {
            XCTFail("Should create URL")
            return
        }
        let response = FileUploadResponse(name: "89d74fcfa4faa5561799e5076593f67c_\(parseFile.name)", url: url)
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(response)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = parseFile.savePublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { fetched in

            XCTAssertEqual(fetched.name, response.name)
            XCTAssertEqual(fetched.url, response.url)
        })
        publisher.store(in: &current)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testSaveFileProgress() throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Fetch")

        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
        }
        let parseFile = ParseFile(name: "sampleData.txt", data: sampleData)

        // swiftlint:disable:next line_length
        guard let url = URL(string: "http://localhost:1337/parse/files/applicationId/89d74fcfa4faa5561799e5076593f67c_sampleData.txt") else {
            XCTFail("Should create URL")
            return
        }
        let response = FileUploadResponse(name: "89d74fcfa4faa5561799e5076593f67c_\(parseFile.name)", url: url)
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(response)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = parseFile.savePublisher(progress: { (_, _, totalDownloaded, totalExpected) in
            let currentProgess = Double(totalDownloaded)/Double(totalExpected) * 100
            XCTAssertGreaterThan(currentProgess, -1)
        }).sink(receiveCompletion: { result in

            if case let .failure(error) = result {
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()

        }, receiveValue: { fetched in

            XCTAssertEqual(fetched.name, response.name)
            XCTAssertEqual(fetched.url, response.url)
        })
        publisher.store(in: &current)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testDelete() throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Fetch")

        // swiftlint:disable:next line_length
        guard let parseFileURL = URL(string: "http://localhost:1337/parse/files/applicationId/d3a37aed0672a024595b766f97133615_logo.svg") else {
            XCTFail("Should create URL")
            return
        }
        var parseFile = ParseFile(name: "d3a37aed0672a024595b766f97133615_logo.svg", cloudURL: parseFileURL)
        parseFile.url = parseFileURL

        let response = FileUploadResponse(name: "d3a37aed0672a024595b766f97133615_logo.svg",
                                          url: parseFileURL)
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(response)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let publisher = parseFile.deletePublisher(options: [.usePrimaryKey])
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { _ in

        })
        publisher.store(in: &current)

        wait(for: [expectation1], timeout: 20.0)
    }
}

#endif
