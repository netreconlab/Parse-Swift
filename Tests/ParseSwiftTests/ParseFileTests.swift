//
//  ParseFileTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/23/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

class ParseFileTests: XCTestCase { // swiftlint:disable:this type_body_length

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
        URLSession.parse.configuration.urlCache?.removeAllCachedResponses()
        #if !os(Linux) && !os(Android) && !os(Windows)
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

    func testUploadCommand() async throws {
        guard let url = URL(string: "http://localhost/") else {
            XCTFail("Should have created url")
            return
        }
        let file = ParseFile(name: "a", cloudURL: url)

        let command = try file.uploadFileCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/files/a")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)
        XCTAssertNil(command.body)

        let file2 = ParseFile(cloudURL: url)

        let command2 = try file2.uploadFileCommand()
        XCTAssertNotNil(command2)
        XCTAssertEqual(command2.path.urlComponent, "/files/file")
        XCTAssertEqual(command2.method, API.Method.POST)
        XCTAssertNil(command2.params)
        XCTAssertNil(command2.body)
    }

    func testUploadCommandDontAllowUpdate() async throws {
        guard let url = URL(string: "http://localhost/") else {
            XCTFail("Should have created url")
            return
        }

        var file = ParseFile(cloudURL: url)
        file.url = url
        XCTAssertThrowsError(try file.uploadFileCommand())
    }

    func testDeleteCommand() {
        guard let url = URL(string: "http://localhost/") else {
            XCTFail("Should have created url")
            return
        }
        var file = ParseFile(name: "a", cloudURL: url)
        file.url = url
        let command = file.deleteFileCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/files/a")
        XCTAssertEqual(command.method, API.Method.DELETE)
        XCTAssertNil(command.params)
        XCTAssertNil(command.body)

        var file2 = ParseFile(cloudURL: url)
        file2.url = url
        let command2 = file2.deleteFileCommand()
        XCTAssertNotNil(command2)
        XCTAssertEqual(command2.path.urlComponent, "/files/file")
        XCTAssertEqual(command2.method, API.Method.DELETE)
        XCTAssertNil(command2.params)
        XCTAssertNil(command2.body)
    }

    func testDownloadCommand() {
        guard let url = URL(string: "http://localhost/") else {
            XCTFail("Should have created url")
            return
        }
        var file = ParseFile(name: "a", cloudURL: url)
        file.url = url
        let command = file.downloadFileCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/files/a")
        XCTAssertEqual(command.method, API.Method.GET)
        XCTAssertNil(command.params)
        XCTAssertNil(command.body)

        let file2 = ParseFile(cloudURL: url)
        let command2 = file2.downloadFileCommand()
        XCTAssertNotNil(command2)
        XCTAssertEqual(command2.path.urlComponent, "/files/file")
        XCTAssertEqual(command2.method, API.Method.GET)
        XCTAssertNil(command2.params)
        XCTAssertNil(command2.body)
    }

    func testLocalUUID() async throws {
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
        }
        let parseFile = ParseFile(name: "sampleData.txt", data: sampleData)
        let localId = parseFile.id
        XCTAssertNotNil(localId)
        XCTAssertEqual(localId,
                       parseFile.id,
                       "localId should remain the same no matter how many times the getter is called")
    }

    func testFileHashable() async throws {
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
        }

        guard let sampleData2 = "Bye World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
        }

        guard let url1 = URL(string: "https://parseplatform.org/img/logo.svg"),
              let url2 = URL(string: "https://parseplatform.org/img/logo2.svg") else {
            throw ParseError(code: .otherCause, message: "Should have created urls")
        }

        var parseFile1 = ParseFile(name: "sampleData.txt", data: sampleData)
        var parseFile2 = ParseFile(name: "sampleData2.txt", data: sampleData)
        var parseFile3 = ParseFile(name: "sampleData3.txt", data: sampleData)
        var parseFile4 = ParseFile(name: "sampleData.txt", data: sampleData2)
        XCTAssertEqual(parseFile1.id, parseFile1.id, "no urls, but names and data should be the same")
        XCTAssertNotEqual(parseFile1.id, parseFile2.id, "no urls, but names and data are different")
        XCTAssertNotEqual(parseFile1.id, parseFile4.id, "no urls, but names are the same, data is different")
        parseFile1.data = nil
        parseFile2.data = nil
        parseFile4.data = nil
        XCTAssertNotEqual(parseFile1.id, parseFile2.id, "no urls or data, but are different")
        XCTAssertEqual(parseFile1.id, parseFile4.id, "no urls or data, but names are the same")
        parseFile1.data = sampleData
        parseFile2.data = sampleData
        parseFile3.data = sampleData2
        parseFile1.url = url1
        parseFile2.url = url2
        parseFile3.url = url1
        XCTAssertNotEqual(parseFile1.id, parseFile2.id, "different urls, url takes precedence over localId")
        XCTAssertEqual(parseFile1.id, parseFile1.id, "same urls and same names")
        XCTAssertNotEqual(parseFile1.id, parseFile3.id, "same urls, but different names")
        parseFile1.url = nil
        parseFile2.url = nil
        parseFile3.url = nil
        XCTAssertNotEqual(parseFile1.id, parseFile2.id, "no urls, but localIds should be different")
        parseFile1.cloudURL = url1
        parseFile2.cloudURL = url2
        parseFile3.cloudURL = url1
        XCTAssertEqual(parseFile1.id, parseFile1.id, "no urls, but cloud urls and names are the same")
        XCTAssertNotEqual(parseFile1.id, parseFile2.id, "no urls, cloud urls and name are different")
        XCTAssertNotEqual(parseFile1.id, parseFile3.id, "no urls, but cloud urls are the same, but names are different")
        parseFile4.cloudURL = url2
        XCTAssertNotEqual(parseFile1.id, parseFile4.id, "no urls, cloud urls are different, but names are the same")
    }

    func testDebugString() async throws {
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
        }
        let parseFile = ParseFile(name: "sampleData.txt",
                                  data: sampleData,
                                  metadata: ["Testing": "123"],
                                  tags: ["Hey": "now"])
        XCTAssertEqual(parseFile.debugDescription,
                       "{\"__type\":\"File\",\"name\":\"sampleData.txt\"}")
        XCTAssertEqual(parseFile.description,
                       "{\"__type\":\"File\",\"name\":\"sampleData.txt\"}")
    }

    func testDebugStringWithFolderInName() async throws {
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
        }
        let parseFile = ParseFile(name: "myFolder/sampleData.txt",
                                  data: sampleData,
                                  metadata: ["Testing": "123"],
                                  tags: ["Hey": "now"])
        XCTAssertEqual(parseFile.debugDescription,
                       "{\"__type\":\"File\",\"name\":\"myFolder\\/sampleData.txt\"}")
        XCTAssertEqual(parseFile.description,
                       "{\"__type\":\"File\",\"name\":\"myFolder\\/sampleData.txt\"}")
    }

    func testSave() async throws {
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
        }
        let parseFile = ParseFile(name: "sampleData.txt",
                                  data: sampleData,
                                  metadata: ["Testing": "123"],
                                  tags: ["Hey": "now"])

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

        let savedFile = try await parseFile.save()
        XCTAssertEqual(savedFile.name, response.name)
        XCTAssertEqual(savedFile.url, response.url)
        let isSavedBefore = try await parseFile.isSaved()
        XCTAssertFalse(isSavedBefore)
        let isSavedAfter = try await savedFile.isSaved()
        XCTAssertTrue(isSavedAfter)
    }

    @MainActor
    func testSaveLocalFile() async throws {
        let tempFilePath = URL(fileURLWithPath: "\(temporaryDirectory)sampleData.txt")
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
        }
        try sampleData.write(to: tempFilePath)

        let parseFile = ParseFile(name: "sampleData.txt", localURL: tempFilePath)

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

        let savedFile = try await parseFile.save()
        XCTAssertEqual(savedFile.name, response.name)
        XCTAssertEqual(savedFile.url, response.url)
        XCTAssertEqual(savedFile.localURL, tempFilePath)
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func testSaveWithSpecifyingMime() async throws {
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
        }
        let parseFile = ParseFile(data: sampleData, mimeType: "application/txt")

        // swiftlint:disable:next line_length
        guard let url = URL(string: "http://localhost:1337/parse/files/applicationId/89d74fcfa4faa5561799e5076593f67c_file") else {
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

        let savedFile = try await parseFile.save()
        XCTAssertEqual(savedFile.name, response.name)
        XCTAssertEqual(savedFile.url, response.url)
    }

    func testSaveCloudFile() async throws {
        guard let tempFilePath = URL(string: "https://parseplatform.org/img/logo.svg") else {
            XCTFail("Should create URL")
            return
        }

        let parseFile = ParseFile(name: "logo.svg", cloudURL: tempFilePath)

        // swiftlint:disable:next line_length
        guard let url = URL(string: "http://localhost:1337/parse/files/applicationId/89d74fcfa4faa5561799e5076593f67c_logo.svg") else {
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

        let savedFile = try await parseFile.save()
        XCTAssertEqual(savedFile.name, response.name)
        XCTAssertEqual(savedFile.url, response.url)
        XCTAssertEqual(savedFile.cloudURL, tempFilePath)
        XCTAssertNotNil(savedFile.localURL)
    }

    func testFetchFile() async throws {
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

        let fetchedFile = try await parseFile.fetch()
        XCTAssertEqual(fetchedFile.name, response.name)
        XCTAssertEqual(fetchedFile.url, response.url)
        XCTAssertNotNil(fetchedFile.localURL)

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        let fetchedFileCached = try await parseFile.fetch(options: [.cachePolicy(.returnCacheDataDontLoad)])
        XCTAssertEqual(fetchedFileCached, fetchedFile)
    }

    func testFetchFileLoadFromRemote() async throws {
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

        let fetchedFile = try await parseFile.fetch(options: [.cachePolicy(.reloadIgnoringLocalAndRemoteCacheData)])
        XCTAssertEqual(fetchedFile.name, response.name)
        XCTAssertEqual(fetchedFile.url, response.url)
        XCTAssertNotNil(fetchedFile.localURL)

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        let fetchedFileCached = try await parseFile.fetch(options: [.cachePolicy(.returnCacheDataDontLoad)])
        XCTAssertEqual(fetchedFileCached, fetchedFile)
    }

    func testFetchFileLoadFromCacheNoCache() async throws {
        // swiftlint:disable:next line_length
        guard let parseFileURL = URL(string: "http://localhost:1337/parse/files/applicationId/d3a37aed0672a024595b766f97133615_logo.svg") else {
            XCTFail("Should create URL")
            return
        }
        var parseFile = ParseFile(name: "d3a37aed0672a024595b766f97133615_logo.svg", cloudURL: parseFileURL)
        parseFile.url = parseFileURL

        do {
            _ = try await parseFile.fetch(options: [.cachePolicy(.returnCacheDataDontLoad)])
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(parseError.code, .unsavedFileFailure)
        }
    }

    func testFetchFileWithDirectoryInName() async throws {
        // swiftlint:disable:next line_length
        guard let parseFileURL = URL(string: "http://localhost:1337/parse/files/applicationId/d3a37aed0672a024595b766f97133615_logo.svg") else {
            XCTFail("Should create URL")
            return
        }
        var parseFile = ParseFile(name: "myFolder/d3a37aed0672a024595b766f97133615_logo.svg", cloudURL: parseFileURL)
        parseFile.url = parseFileURL

        let response = FileUploadResponse(name: "myFolder/d3a37aed0672a024595b766f97133615_logo.svg",
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

        let fetchedFile = try await parseFile.fetch()
        XCTAssertEqual(fetchedFile.name, response.name)
        XCTAssertEqual(fetchedFile.url, response.url)
        guard let localURL = fetchedFile.localURL else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertFalse(localURL.pathComponents.contains("myFolder"))

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        let fetchedFileCached = try await parseFile.fetch(options: [.cachePolicy(.returnCacheDataDontLoad)])
        XCTAssertEqual(fetchedFileCached, fetchedFile)
    }

    func testFetchFileProgress() async throws {
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

        let fetchedFile = try await parseFile.fetch { (_, _, totalDownloaded, totalExpected) in
            let currentProgess = Double(totalDownloaded)/Double(totalExpected) * 100
            XCTAssertGreaterThan(currentProgess, -1)
        }
        XCTAssertEqual(fetchedFile.name, response.name)
        XCTAssertEqual(fetchedFile.url, response.url)
        XCTAssertNotNil(fetchedFile.localURL)

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        // swiftlint:disable:next line_length
        let fetchedFileCached = try await parseFile.fetch(options: [.cachePolicy(.returnCacheDataDontLoad)]) { (_, _, totalDownloaded, totalExpected) in
            let currentProgess = Double(totalDownloaded)/Double(totalExpected) * 100
            XCTAssertGreaterThan(currentProgess, -1)
        }
        XCTAssertEqual(fetchedFileCached, fetchedFile)
    }

    func testFetchFileProgressLoadFromRemote() async throws {
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
        // swiftlint:disable:next line_length
        let fetchedFile = try await parseFile.fetch(options: [.cachePolicy(.reloadIgnoringLocalAndRemoteCacheData)]) { (_, _, totalDownloaded, totalExpected) in
            let currentProgess = Double(totalDownloaded)/Double(totalExpected) * 100
            XCTAssertGreaterThan(currentProgess, -1)
        }
        XCTAssertEqual(fetchedFile.name, response.name)
        XCTAssertEqual(fetchedFile.url, response.url)
        XCTAssertNotNil(fetchedFile.localURL)

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        // swiftlint:disable:next line_length
        let fetchedFileCached = try await parseFile.fetch(options: [.cachePolicy(.returnCacheDataDontLoad)]) { (_, _, totalDownloaded, totalExpected) in
            let currentProgess = Double(totalDownloaded)/Double(totalExpected) * 100
            XCTAssertGreaterThan(currentProgess, -1)
        }
        XCTAssertEqual(fetchedFileCached, fetchedFile)
    }

    func testFetchFileProgressFromCacheNoCache() async throws {
        // swiftlint:disable:next line_length
        guard let parseFileURL = URL(string: "http://localhost:1337/parse/files/applicationId/d3a37aed0672a024595b766f97133615_logo.svg") else {
            XCTFail("Should create URL")
            return
        }
        var parseFile = ParseFile(name: "d3a37aed0672a024595b766f97133615_logo.svg", cloudURL: parseFileURL)
        parseFile.url = parseFileURL

        do {
            // swiftlint:disable:next line_length
            _ = try await parseFile.fetch(options: [.cachePolicy(.returnCacheDataDontLoad)]) { (_, _, totalDownloaded, totalExpected) in
                let currentProgess = Double(totalDownloaded)/Double(totalExpected) * 100
                XCTAssertGreaterThan(currentProgess, -1)
            }
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(parseError.code, .unsavedFileFailure)
        }
    }

    func testDeleteFile() async throws {
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

        try await parseFile.delete(options: [.usePrimaryKey])
    }

    func testCloudFileProgress() async throws {
        guard let tempFilePath = URL(string: "https://parseplatform.org/img/logo.svg") else {
            XCTFail("Should create URL")
            return
        }

        let parseFile = ParseFile(name: "logo.svg", cloudURL: tempFilePath)

        // swiftlint:disable:next line_length
        guard let url = URL(string: "http://localhost:1337/parse/files/applicationId/89d74fcfa4faa5561799e5076593f67c_logo.svg") else {
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

        let savedFile = try await parseFile.save { (_, _, totalWritten, totalExpected) in
            let currentProgess = Double(totalWritten)/Double(totalExpected) * 100
            XCTAssertGreaterThan(currentProgess, -1)
        }
        XCTAssertEqual(savedFile.name, response.name)
        XCTAssertEqual(savedFile.url, response.url)
        XCTAssertEqual(savedFile.cloudURL, tempFilePath)
        XCTAssertNotNil(savedFile.localURL)
    }

    func testCloudFileCancel() async throws {
        guard let tempFilePath = URL(string: "https://parseplatform.org/img/logo.svg") else {
            XCTFail("Should create URL")
            return
        }

        let parseFile = ParseFile(name: "logo.svg", cloudURL: tempFilePath)

        // swiftlint:disable:next line_length
        guard let url = URL(string: "http://localhost:1337/parse/files/applicationId/89d74fcfa4faa5561799e5076593f67c_logo.svg") else {
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

        let savedFile = try await parseFile.save { (task, _, totalWritten, totalExpected) in
            let currentProgess = Double(totalWritten)/Double(totalExpected) * 100
            if currentProgess > 10 {
                task.cancel()
            }
        }
        XCTAssertEqual(savedFile.name, response.name)
        XCTAssertEqual(savedFile.url, response.url)
        XCTAssertEqual(savedFile.cloudURL, tempFilePath)
        XCTAssertNotNil(savedFile.localURL)
    }
    #endif

    func testSaveFileStream() async throws {
        let tempFilePath = URL(fileURLWithPath: "\(temporaryDirectory)sampleData.dat")
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
        }
        try sampleData.write(to: tempFilePath)

        let parseFile = ParseFile(name: "sampleData.data", localURL: tempFilePath)

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

        guard let stream = InputStream(fileAtPath: tempFilePath.relativePath) else {
            throw ParseError(code: .otherCause, message: "Should have created file stream")
        }
        let expectation1 = XCTestExpectation(description: "ParseFile async")
        try parseFile.save(options: [], stream: stream, progress: nil) { error in
            XCTAssertNil(error)
            expectation1.fulfill()
        }
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testSaveFileStreamProgress() async throws {
        let tempFilePath = URL(fileURLWithPath: "\(temporaryDirectory)sampleData.dat")
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
        }
        try sampleData.write(to: tempFilePath)

        let parseFile = ParseFile(name: "sampleData.data", localURL: tempFilePath)

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

        guard let stream = InputStream(fileAtPath: tempFilePath.relativePath) else {
            throw ParseError(code: .otherCause, message: "Should have created file stream")
        }

        let expectation1 = XCTestExpectation(description: "ParseFile async")

        try parseFile.save(stream: stream, progress: { (_, _, totalWritten, totalExpected) in
            let currentProgess = Double(totalWritten)/Double(totalExpected) * 100
            XCTAssertGreaterThan(currentProgess, -1)
        }) { error in // swiftlint:disable:this multiple_closures_with_trailing_closure
            XCTAssertNil(error)
            expectation1.fulfill()
        }
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testSaveFileStreamCancel() async throws {
        let tempFilePath = URL(fileURLWithPath: "\(temporaryDirectory)sampleData.dat")
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
        }
        try sampleData.write(to: tempFilePath)

        let parseFile = ParseFile(name: "sampleData.data", localURL: tempFilePath)

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

        guard let stream = InputStream(fileAtPath: tempFilePath.relativePath) else {
            throw ParseError(code: .otherCause, message: "Should have created file stream")
        }

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        try parseFile.save(stream: stream, progress: { (task, _, totalWritten, totalExpected) in
            let currentProgess = Double(totalWritten)/Double(totalExpected) * 100
            if currentProgess > 10 {
                task.cancel()
            }
        }) { error in // swiftlint:disable:this multiple_closures_with_trailing_closure
            XCTAssertNil(error)
            expectation1.fulfill()
        }
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testUpdateFileError() async throws {
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
        }
        var parseFile = ParseFile(name: "sampleData.txt",
                                  data: sampleData,
                                  metadata: ["Testing": "123"],
                                  tags: ["Hey": "now"])
        parseFile.url = URL(string: "http://localhost/")

        do {
            _ = try await parseFile.save()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.containedIn([.otherCause]))
        }
    }

#if compiler(>=5.8.0) || (compiler(<5.8.0) && !os(iOS) && !os(tvOS))
    #if !os(Linux) && !os(Android) && !os(Windows)
    func testSaveAysnc() async throws {

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

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        parseFile.save { result in

            switch result {
            case .success(let saved):
                XCTAssertEqual(saved.name, response.name)
                XCTAssertEqual(saved.url, response.url)

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testSaveFileProgressAsync() async throws {
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

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        parseFile.save(progress: { (_, _, totalWritten, totalExpected) in
            let currentProgess = Double(totalWritten)/Double(totalExpected) * 100
            XCTAssertGreaterThan(currentProgess, -1)
        }) { result in // swiftlint:disable:this multiple_closures_with_trailing_closure

            switch result {
            case .success(let saved):
                XCTAssertEqual(saved.name, response.name)
                XCTAssertEqual(saved.url, response.url)

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testSaveFileCancelAsync() async throws {
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

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        parseFile.save(progress: { (task, _, totalWritten, totalExpected) in
            let currentProgess = Double(totalWritten)/Double(totalExpected) * 100
            if currentProgess > 10 {
                task.cancel()
            }
        }) { result in // swiftlint:disable:this multiple_closures_with_trailing_closure

            switch result {
            case .success(let saved):
                XCTAssertEqual(saved.name, response.name)
                XCTAssertEqual(saved.url, response.url)

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testSaveWithSpecifyingMimeAysnc() async throws {

        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
        }
        let parseFile = ParseFile(data: sampleData, mimeType: "application/txt")

        // swiftlint:disable:next line_length
        guard let url = URL(string: "http://localhost:1337/parse/files/applicationId/89d74fcfa4faa5561799e5076593f67c_file") else {
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

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        parseFile.save { result in

            switch result {
            case .success(let saved):
                XCTAssertEqual(saved.name, response.name)
                XCTAssertEqual(saved.url, response.url)

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testSaveLocalFileAysnc() async throws {

        let tempFilePath = URL(fileURLWithPath: "\(temporaryDirectory)sampleData.txt")
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
        }
        try sampleData.write(to: tempFilePath)

        let parseFile = ParseFile(name: "sampleData.txt", localURL: tempFilePath)

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

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        parseFile.save { result in

            switch result {
            case .success(let saved):
                XCTAssertEqual(saved.name, response.name)
                XCTAssertEqual(saved.url, response.url)
                XCTAssertEqual(saved.localURL, tempFilePath)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }
    #endif

    func testUpdateErrorAysnc() async throws {

        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
        }
        var parseFile = ParseFile(name: "sampleData.txt", data: sampleData)
        parseFile.url = URL(string: "http://localhost/")

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        parseFile.save { result in

            switch result {
            case .success:
                XCTFail("Should have returned error")
            case .failure(let error):
                XCTAssertTrue(error.message.contains("File is already"))
            }
            expectation1.fulfill()
        }
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    #if !os(Linux) && !os(Android) && !os(Windows)

    // URL Mocker is not able to mock this in linux and tests fail, so do not run.
    func testFetchFileCancelAsync() async throws {
        // swiftlint:disable:next line_length
        guard let parseFileURL = URL(string: "http://localhost:1337/parse/files/applicationId/7793939a2e59b98138c1bbf2412a060c_logo.svg") else {
            XCTFail("Should create URL")
            return
        }
        var parseFile = ParseFile(name: "7793939a2e59b98138c1bbf2412a060c_logo.svg", cloudURL: parseFileURL)
        parseFile.url = parseFileURL

        let response = FileUploadResponse(name: "7793939a2e59b98138c1bbf2412a060c_logo.svg",
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

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        parseFile.fetch(progress: { (task, _, totalDownloaded, totalExpected) in
            let currentProgess = Double(totalDownloaded)/Double(totalExpected) * 100
            if currentProgess > 10 {
                task.cancel()
            }
        }) { result in // swiftlint:disable:this multiple_closures_with_trailing_closure

            switch result {
            case .success(let fetched):
                XCTAssertEqual(fetched.name, response.name)
                XCTAssertEqual(fetched.url, response.url)
                XCTAssertNotNil(fetched.localURL)

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testFetchFileAysnc() async throws {

        // swiftlint:disable:next line_length
        guard let parseFileURL = URL(string: "http://localhost:1337/parse/files/applicationId/7793939a2e59b98138c1bbf2412a060c_logo.svg") else {
            XCTFail("Should create URL")
            return
        }
        var parseFile = ParseFile(name: "7793939a2e59b98138c1bbf2412a060c_logo.svg", cloudURL: parseFileURL)
        parseFile.url = parseFileURL

        let response = FileUploadResponse(name: "7793939a2e59b98138c1bbf2412a060c_logo.svg",
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

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        parseFile.fetch { result in

            switch result {
            case .success(let fetched):
                XCTAssertEqual(fetched.name, response.name)
                XCTAssertEqual(fetched.url, response.url)
                XCTAssertNotNil(fetched.localURL)

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testFetchFileProgressAsync() async throws {
        // swiftlint:disable:next line_length
        guard let parseFileURL = URL(string: "http://localhost:1337/parse/files/applicationId/6f9988ab5faa28f7247664c6ffd9fd85_logo.svg") else {
            XCTFail("Should create URL")
            return
        }
        var parseFile = ParseFile(name: "6f9988ab5faa28f7247664c6ffd9fd85_logo.svg", cloudURL: parseFileURL)
        parseFile.url = parseFileURL

        let response = FileUploadResponse(name: "6f9988ab5faa28f7247664c6ffd9fd85_logo.svg",
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

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        parseFile.fetch(progress: { (_, _, totalDownloaded, totalExpected) in
            let currentProgess = Double(totalDownloaded)/Double(totalExpected) * 100
            XCTAssertGreaterThan(currentProgess, -1)
        }) { result in // swiftlint:disable:this multiple_closures_with_trailing_closure

            switch result {
            case .success(let fetched):
                XCTAssertEqual(fetched.name, response.name)
                XCTAssertEqual(fetched.url, response.url)
                XCTAssertNotNil(fetched.localURL)

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testSaveCloudFileProgressAysnc() async throws {

        guard let tempFilePath = URL(string: "https://parseplatform.org/img/logo.svg") else {
            XCTFail("Should create URL")
            return
        }

        let parseFile = ParseFile(name: "logo.svg", cloudURL: tempFilePath)

        // swiftlint:disable:next line_length
        guard let url = URL(string: "http://localhost:1337/parse/files/applicationId/89d74fcfa4faa5561799e5076593f67c_logo.svg") else {
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

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        parseFile.save(progress: { (_, _, totalWritten, totalExpected) in
            let currentProgess = Double(totalWritten)/Double(totalExpected) * 100
            XCTAssertGreaterThan(currentProgess, -1)
        }) { result in // swiftlint:disable:this multiple_closures_with_trailing_closure

            switch result {
            case .success(let saved):
                XCTAssertEqual(saved.name, response.name)
                XCTAssertEqual(saved.url, response.url)
                XCTAssertEqual(saved.cloudURL, tempFilePath)
                XCTAssertNotNil(saved.localURL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testSaveCloudFileAysnc() async throws {

        guard let tempFilePath = URL(string: "https://parseplatform.org/img/logo.svg") else {
            XCTFail("Should create URL")
            return
        }

        let parseFile = ParseFile(name: "logo.svg", cloudURL: tempFilePath)

        // swiftlint:disable:next line_length
        guard let url = URL(string: "http://localhost:1337/parse/files/applicationId/89d74fcfa4faa5561799e5076593f67c_logo.svg") else {
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

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        parseFile.save { result in

            switch result {
            case .success(let saved):
                XCTAssertEqual(saved.name, response.name)
                XCTAssertEqual(saved.url, response.url)
                XCTAssertEqual(saved.cloudURL, tempFilePath)
                XCTAssertNotNil(saved.localURL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testDeleteFileAysnc() async throws {
        // swiftlint:disable:next line_length
        guard let parseFileURL = URL(string: "http://localhost:1337/parse/files/applicationId/1b0683d529463e173cbf8046d7d9a613_logo.svg") else {
            XCTFail("Should create URL")
            return
        }
        var parseFile = ParseFile(name: "1b0683d529463e173cbf8046d7d9a613_logo.svg", cloudURL: parseFileURL)
        parseFile.url = parseFileURL

        let response = FileUploadResponse(name: "1b0683d529463e173cbf8046d7d9a613_logo.svg",
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

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        parseFile.delete(options: [.usePrimaryKey]) { result in

            if case let .failure(error) = result {
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testDeleteFileAysncError() async throws {
        // swiftlint:disable:next line_length
        guard let parseFileURL = URL(string: "http://localhost:1337/parse/files/applicationId/1b0683d529463e173cbf8046d7d9a613_logo.svg") else {
            XCTFail("Should create URL")
            return
        }
        var parseFile = ParseFile(name: "1b0683d529463e173cbf8046d7d9a613_logo.svg", cloudURL: parseFileURL)
        parseFile.url = parseFileURL

        let response = ParseError(code: .fileTooLarge, message: "Too large.")
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

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        parseFile.delete(options: [.usePrimaryKey]) { result in

            if case .success = result {
                XCTFail("Should have failed with error")
            }
            expectation1.fulfill()
        }
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }
    #endif
#endif
} // swiftlint:disable:this file_length
