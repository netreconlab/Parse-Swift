//
//  ParseFileTransferableTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/13/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

class ParseFileTransferableTests: XCTestCase, @unchecked Sendable {
    let temporaryDirectory = "\(NSTemporaryDirectory())test/"

    struct FileUploadResponse: Codable, Equatable {
        let name: String
        let url: URL
    }

    final class TestFileTransfer: ParseFileTransferable {
        let name: String
        let url: URL

        init(name: String, url: URL?) throws {
            guard let url = url else {
                throw ParseError(code: .otherCause,
                                 message: "URL should not be nil")
            }
            self.url = url
            self.name = name
        }

        func upload(with request: URLRequest,
                    from bodyData: Data?,
                    // swiftlint:disable:next line_length
                    completion: @escaping @Sendable (Data?, URLResponse?, URLRequest?, Error?) -> Void) throws -> URLSessionUploadTask {
            try fakeUpload(completion: completion)
        }

        func upload(with request: URLRequest,
                    fromFile fileURL: URL,
                    // swiftlint:disable:next line_length
                    completion: @escaping @Sendable (Data?, URLResponse?, URLRequest?, Error?) -> Void) throws -> URLSessionUploadTask {
            try fakeUpload(completion: completion)
        }

        func fakeUpload(completion: @escaping @Sendable (Data?,
                                               URLResponse?,
                                               URLRequest?,
                                               Error?) -> Void) throws -> URLSessionUploadTask {
            let response = try makeSuccessfulUploadResponse(name, url: url)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                completion(response.0, response.1, nil, nil)
            }
            return try makeDummyUploadTask()
        }
    }

    final class TestFileTransferThrowError: ParseFileTransferable {
        let name: String
        let url: URL

        init(name: String, url: URL?) throws {
            guard let url = url else {
                throw ParseError(code: .otherCause,
                                 message: "URL should not be nil")
            }
            self.url = url
            self.name = name
        }

        func upload(with request: URLRequest,
                    from bodyData: Data?,
                    // swiftlint:disable:next line_length
                    completion: @escaping (Data?, URLResponse?, URLRequest?, Error?) -> Void) throws -> URLSessionUploadTask {
            throw ParseError(code: .otherCause, message: "Thrown on purpose")
        }

        func upload(with request: URLRequest,
                    fromFile fileURL: URL,
                    // swiftlint:disable:next line_length
                    completion: @escaping (Data?, URLResponse?, URLRequest?, Error?) -> Void) throws -> URLSessionUploadTask {
            throw ParseError(code: .otherCause, message: "Thrown on purpose")
        }
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
        URLSession.parse.configuration.urlCache?.removeAllCachedResponses()
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

    func testSDKInitializers() async throws {
        guard let url = URL(string: "http://localhost:1337/parse") else {
            XCTFail("Should create valid URL")
            return
        }
        let fileTransferAdapter = try TestFileTransfer(name: "test", url: url)
        let fileTransferAdapterOther = try TestFileTransfer(name: "test", url: url)
        XCTAssertTrue(fileTransferAdapter !== fileTransferAdapterOther)
        XCTAssertTrue(ParseSwift.configuration.parseFileTransfer !== fileTransferAdapter)
        try await ParseSwift.initialize(applicationId: "applicationId",
                                        clientKey: "clientKey",
                                        primaryKey: "primaryKey",
                                        serverURL: url,
                                        parseFileTransfer: fileTransferAdapter)
        XCTAssertTrue(ParseSwift.configuration.parseFileTransfer === fileTransferAdapter)
        try await ParseSwift.initialize(configuration: .init(applicationId: "applicationId",
                                                             clientKey: "clientKey",
                                                             primaryKey: "primaryKey",
                                                             serverURL: url,
                                                             parseFileTransfer: fileTransferAdapterOther))
        XCTAssertTrue(ParseSwift.configuration.parseFileTransfer === fileTransferAdapterOther)
    }

    func testMakeSuccessfulUploadResponse() throws {
        guard let url = URL(string: "http://localhost:1337/parse") else {
            XCTFail("Should create valid URL")
            return
        }
        let fileTransferAdapter = try TestFileTransfer(name: "test", url: url)
        let originalUploadResponse = FileUploadResponse(name: "hello", url: url)
        let fileUploadResponseData = try fileTransferAdapter.makeSuccessfulUploadResponse("hello",
                                                                                          url: url)
        let decodedUploadResponse = try ParseCoding.jsonDecoder().decode(FileUploadResponse.self,
                                                                         from: fileUploadResponseData.0)
        XCTAssertEqual(originalUploadResponse, decodedUploadResponse)
        XCTAssertEqual(fileUploadResponseData.1?.url, url)
        XCTAssertEqual(fileUploadResponseData.1?.statusCode, 200)
    }

    func testMakeDummyUploadTask() throws {
        XCTAssertNoThrow(try ParseSwift.configuration.parseFileTransfer.makeDummyUploadTask())
    }

    func testSaveFromData() throws {
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
        }
        let fileName = "sampleData.txt"
        let parseFile = ParseFile(name: "sampleData.txt",
                                  data: sampleData,
                                  metadata: ["Testing": "123"],
                                  tags: ["Hey": "now"])

        // swiftlint:disable:next line_length
        guard let url = URL(string: "http://localhost:1337/parse/files/applicationId/89d74fcfa4faa5561799e5076593f67c_sampleData.txt") else {
            XCTFail("Should create URL")
            return
        }
        let fileTransferAdapter = try TestFileTransfer(name: fileName, url: url)
        Parse.configuration.parseFileTransfer = fileTransferAdapter

        let expectation1 = XCTestExpectation(description: "ParseFile save")
        parseFile.save { result in
            switch result {
            case .success(let savedFile):
                XCTAssertEqual(savedFile.name, fileName)
                XCTAssertEqual(savedFile.url, url)
            case .failure(let error):
                XCTFail("\(error)")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testSaveFromFile() throws {
        let tempFilePath = URL(fileURLWithPath: "\(temporaryDirectory)sampleData.txt")
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
        }
        try sampleData.write(to: tempFilePath)
        let fileName = "sampleData.txt"
        let parseFile = ParseFile(name: fileName, localURL: tempFilePath)
        // swiftlint:disable:next line_length
        guard let url = URL(string: "http://localhost:1337/parse/files/applicationId/89d74fcfa4faa5561799e5076593f67c_sampleData.txt") else {
            XCTFail("Should create URL")
            return
        }
        let fileTransferAdapter = try TestFileTransfer(name: fileName, url: url)
        Parse.configuration.parseFileTransfer = fileTransferAdapter

        let expectation1 = XCTestExpectation(description: "ParseFile save")
        parseFile.save { result in
            switch result {
            case .success(let savedFile):
                XCTAssertEqual(savedFile.name, fileName)
                XCTAssertEqual(savedFile.url, url)
            case .failure(let error):
                XCTFail("\(error)")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testSaveFromDataThrowError() throws {
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
        }
        let fileName = "sampleData.txt"
        let parseFile = ParseFile(name: "sampleData.txt",
                                  data: sampleData,
                                  metadata: ["Testing": "123"],
                                  tags: ["Hey": "now"])

        // swiftlint:disable:next line_length
        guard let url = URL(string: "http://localhost:1337/parse/files/applicationId/89d74fcfa4faa5561799e5076593f67c_sampleData.txt") else {
            XCTFail("Should create URL")
            return
        }
        let fileTransferAdapter = try TestFileTransferThrowError(name: fileName, url: url)
        Parse.configuration.parseFileTransfer = fileTransferAdapter

        let expectation1 = XCTestExpectation(description: "ParseFile save")
        parseFile.save { result in
            switch result {
            case .success:
                XCTFail("Should have failed")
            case .failure(let error):
                XCTAssertTrue(error.message.contains("purpose"))
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testSaveFromFileThrowError() throws {
        let tempFilePath = URL(fileURLWithPath: "\(temporaryDirectory)sampleData.txt")
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
        }
        try sampleData.write(to: tempFilePath)
        let fileName = "sampleData.txt"
        let parseFile = ParseFile(name: fileName, localURL: tempFilePath)
        // swiftlint:disable:next line_length
        guard let url = URL(string: "http://localhost:1337/parse/files/applicationId/89d74fcfa4faa5561799e5076593f67c_sampleData.txt") else {
            XCTFail("Should create URL")
            return
        }
        let fileTransferAdapter = try TestFileTransferThrowError(name: fileName, url: url)
        Parse.configuration.parseFileTransfer = fileTransferAdapter

        let expectation1 = XCTestExpectation(description: "ParseFile save")
        parseFile.save { result in
            switch result {
            case .success:
                XCTFail("Should have failed")
            case .failure(let error):
                XCTAssertTrue(error.message.contains("purpose"))
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }
}
