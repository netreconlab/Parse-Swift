//
//  APICommandTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 7/19/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

// swiftlint:disable type_body_length

class APICommandTests: XCTestCase {

    struct Level: ParseObject {
        var objectId: String?

        var createdAt: Date?

        var updatedAt: Date?

        var ACL: ParseACL?

        var name = "First"

        var originalData: Data?
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
        var sessionToken: String
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

    func userLogin() async {
        let loginResponse = LoginSignupResponse()
        let loginUserName = "hello10"
        let loginPassword = "world"

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        do {
            _ = try await User.login(username: loginUserName, password: loginPassword)
            MockURLProtocol.removeAll()
        } catch {
            XCTFail("Should login")
        }
    }

    func testSetServerURLOption() throws {
        let serverURL1 = API.serverURL(options: [])
        XCTAssertEqual(Parse.configuration.serverURL, serverURL1)
        let newServerURLString = "http://parse:1337/parse"
        let serverURL2 = API.serverURL(options: [.serverURL(newServerURLString)])
        XCTAssertNotEqual(Parse.configuration.serverURL, serverURL2)
        XCTAssertEqual(serverURL2, URL(string: newServerURLString))
        let serverURL3 = API.serverURL(options: [.context("Hello"), .serverURL(newServerURLString)])
        XCTAssertEqual(serverURL2, serverURL3)
        let serverURL4 = API.serverURL(options: [.context("Hello"), .fileSize("500")])
        XCTAssertEqual(serverURL4, serverURL1)
    }

    func testAPISchemasURL() throws {
        XCTAssertEqual(API.Endpoint.schemas.urlComponent, "/schemas")
    }

    func testOptionHasherEquatable() throws {
        var options = API.Options()
        let first = "first"
        let second = "second"
        let firstDictionary = [first: second]
        let secondDictionary = [second: first]
        let firstServerURLString = "http://parse:1337/\(first)"
        let secondServerURLString = "http://parse:1337/\(second)"

        XCTAssertFalse(options.contains(.usePrimaryKey))
        options.insert(.usePrimaryKey)
        XCTAssertTrue(options.contains(.usePrimaryKey))

        XCTAssertFalse(options.contains(.removeMimeType))
        options.insert(.removeMimeType)
        XCTAssertTrue(options.contains(.removeMimeType))

        XCTAssertFalse(options.contains(.sessionToken(first)))
        options.insert(.sessionToken(first))
        XCTAssertTrue(options.contains(.sessionToken(first)))
        XCTAssertFalse(options.contains(.sessionToken(second)))

        XCTAssertFalse(options.contains(.installationId(first)))
        options.insert(.installationId(first))
        XCTAssertTrue(options.contains(.installationId(first)))
        XCTAssertFalse(options.contains(.installationId(second)))

        XCTAssertFalse(options.contains(.mimeType(first)))
        options.insert(.mimeType(first))
        XCTAssertTrue(options.contains(.mimeType(first)))
        XCTAssertFalse(options.contains(.mimeType(second)))

        XCTAssertFalse(options.contains(.fileSize(first)))
        options.insert(.fileSize(first))
        XCTAssertTrue(options.contains(.fileSize(first)))
        XCTAssertFalse(options.contains(.fileSize(second)))

        XCTAssertFalse(options.contains(.metadata(firstDictionary)))
        options.insert(.metadata(firstDictionary))
        XCTAssertTrue(options.contains(.metadata(firstDictionary)))
        XCTAssertFalse(options.contains(.metadata(secondDictionary)))

        XCTAssertFalse(options.contains(.tags(firstDictionary)))
        options.insert(.tags(firstDictionary))
        XCTAssertTrue(options.contains(.tags(firstDictionary)))
        XCTAssertFalse(options.contains(.tags(secondDictionary)))

        XCTAssertFalse(options.contains(.context(first)))
        options.insert(.context(first))
        XCTAssertTrue(options.contains(.context(first)))
        XCTAssertFalse(options.contains(.context(second)))

        XCTAssertFalse(options.contains(.cachePolicy(.returnCacheDataDontLoad)))
        options.insert(.cachePolicy(.returnCacheDataDontLoad))
        XCTAssertTrue(options.contains(.cachePolicy(.returnCacheDataDontLoad)))
        XCTAssertFalse(options.contains(.cachePolicy(.reloadRevalidatingCacheData)))

        XCTAssertFalse(options.contains(.serverURL(firstServerURLString)))
        options.insert(.serverURL(firstServerURLString))
        XCTAssertTrue(options.contains(.serverURL(firstServerURLString)))
        XCTAssertFalse(options.contains(.serverURL(secondServerURLString)))
    }

    func testExecuteCorrectly() async {
        let originalObject = "test"
        MockURLProtocol.mockRequests { _ in
            do {
                return try MockURLResponse(string: originalObject, statusCode: 200)
            } catch {
                return nil
            }
        }
        do {
            let returnedObject =
                try await API.NonParseBodyCommand<NoBody, String>(method: .GET,
                                                                  path: .login,
                                                                  params: nil,
                                                                  mapper: { (data) -> String in
                    return try JSONDecoder().decode(String.self, from: data)
                }).execute(options: [],
                           callbackQueue: .main)
            XCTAssertEqual(originalObject, returnedObject)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // This is how errors from the server should typically come in
    func testErrorFromParseServer() async {
        let originalError = ParseError(code: .otherCause, message: "Could not decode")
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try JSONEncoder().encode(originalError)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                XCTFail("Should encode error")
                return nil
            }
        }

        do {
            _ = try await API.NonParseBodyCommand<NoBody, NoBody>(method: .GET,
                                                                  path: .login,
                                                                  params: nil,
                                                                  mapper: { _ -> NoBody in
                throw originalError
            }).execute(options: [],
                       callbackQueue: .main)
            XCTFail("Should have thrown an error")
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("Should be able unwrap final error to ParseError")
                return
            }
            XCTAssertEqual(originalError.code, error.code)
        }
    }

    // This is how HTTP errors should typically come in
    func testErrorHTTP400JSON() async {
        let parseError = ParseError(code: .connectionFailed, message: "Connection failed")
        let errorKey = "error"
        let errorValue = "yarr"
        let codeKey = "code"
        let codeValue = 100
        let responseDictionary: [String: Any] = [
            errorKey: errorValue,
            codeKey: codeValue
        ]

        MockURLProtocol.mockRequests { _ in
            do {
                let json = try JSONSerialization.data(withJSONObject: responseDictionary, options: [])
                return MockURLResponse(data: json, statusCode: 400)
            } catch {
                XCTFail(error.localizedDescription)
                return nil
            }
        }

        do {
            _ = try await API.NonParseBodyCommand<NoBody, NoBody>(method: .GET,
                                                                  path: .login,
                                                                  params: nil,
                                                                  mapper: { _ -> NoBody in
                throw parseError
            }).execute(options: [],
                       callbackQueue: .main)

            XCTFail("Should have thrown an error")
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("Should be able unwrap final error to ParseError")
                return
            }
            XCTAssertEqual(error.code, parseError.code)
        }
    }

    func testErrorHTTPReturns400NoDataFromServer() async {
        let originalError = ParseError(code: .otherCause, message: "Could not decode")
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(error: originalError) // Status code defaults to 400
        }
        do {
            _ = try await API.NonParseBodyCommand<NoBody, NoBody>(method: .GET,
                                                                  path: .login,
                                                                  params: nil,
                                                                  mapper: { _ -> NoBody in
                throw originalError
            }).execute(options: [],
                       callbackQueue: .main)
            XCTFail("Should have thrown an error")
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("Should be able unwrap final error to ParseError")
                return
            }
            XCTAssertEqual(originalError.code, error.code)
        }
    }

    // This is how errors HTTP errors should typically come in
    func testErrorHTTP500JSON() async {
        let parseError = ParseError(code: .connectionFailed, message: "Connection failed")
        let errorKey = "error"
        let errorValue = "yarr"
        let codeKey = "code"
        let codeValue = 100
        let responseDictionary: [String: Any] = [
            errorKey: errorValue,
            codeKey: codeValue
        ]

        MockURLProtocol.mockRequests { _ in
            do {
                let json = try JSONSerialization.data(withJSONObject: responseDictionary, options: [])
                return MockURLResponse(data: json, statusCode: 500)
            } catch {
                XCTFail(error.localizedDescription)
                return nil
            }
        }

        do {
            _ = try await API.NonParseBodyCommand<NoBody, NoBody>(method: .GET,
                                                                  path: .login,
                                                                  params: nil,
                                                                  mapper: { _ -> NoBody in
                throw parseError
            }).execute(options: [],
                       callbackQueue: .main)

            XCTFail("Should have thrown an error")
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("Should be able unwrap final error to ParseError")
                return
            }
            XCTAssertEqual(error.code, parseError.code)
        }
    }

    func testErrorHTTPReturns500NoDataFromServer() async {
        let originalError = ParseError(code: .otherCause, message: "Could not decode")
        MockURLProtocol.mockRequests { _ in
            var response = MockURLResponse(error: originalError)
            response.statusCode = 500
            return response
        }
        do {
            _ = try await API.NonParseBodyCommand<NoBody, NoBody>(method: .GET,
                                                                  path: .login,
                                                                  params: nil,
                                                                  mapper: { _ -> NoBody in
                throw originalError
            }).execute(options: [],
                       callbackQueue: .main)
            XCTFail("Should have thrown an error")
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("Should be able unwrap final error to ParseError")
                return
            }
            XCTAssertEqual(originalError.code, error.code)
        }
    }

    func testApplicationIdHeader() async throws {
        let headers = try await API.getHeaders(options: [])
        XCTAssertEqual(headers["X-Parse-Application-Id"], ParseSwift.configuration.applicationId)

        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch await post.prepareURLRequest(options: []) {

        case .success(let request):
            XCTAssertEqual(request.allHTTPHeaderFields?["X-Parse-Application-Id"],
                           ParseSwift.configuration.applicationId)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testQueryWhereEncoding() async throws {
        let query = Level.query("name" == "test@parse.com")
        let parameters = try query.getQueryParameters()

        let queryCommand = API.NonParseBodyCommand<Query<Level>, Level?>(
            method: .GET,
            path: query.endpoint,
            params: parameters
        ) { _ in
            return nil
        }

        switch await queryCommand.prepareURLRequest(options: []) {

        case .success(let request):
            XCTAssertEqual(
                request.url?.absoluteString,
                "http://localhost:1337/parse/classes/Level?limit=100&skip=0&where=%7B%22name%22:%22test@parse.com%22%7D"
            )
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testQueryWhereEncodingPlus() async throws {
        let query = Level.query("name" == "test+1@parse.com")
        let parameters = try query.getQueryParameters()

        let queryCommand = API.NonParseBodyCommand<Query<Level>, Level?>(
            method: .GET,
            path: query.endpoint,
            params: parameters
        ) { _ in
            return nil
        }

        switch await queryCommand.prepareURLRequest(options: []) {

        case .success(let request):
            XCTAssertEqual(
                request.url?.absoluteString,
                // swiftlint:disable:next line_length
                "http://localhost:1337/parse/classes/Level?limit=100&skip=0&where=%7B%22name%22:%22test%2B1@parse.com%22%7D"
            )
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testClientKeyHeader() async throws {
        guard let clientKey = ParseSwift.configuration.clientKey else {
            throw ParseError(code: .otherCause, message: "Parse configuration should contain key")
        }

        let headers = try await API.getHeaders(options: [])
        XCTAssertEqual(headers["X-Parse-Client-Key"], clientKey)

        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch await post.prepareURLRequest(options: []) {

        case .success(let request):
            XCTAssertEqual(request.allHTTPHeaderFields?["X-Parse-Client-Key"],
                           clientKey)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testPrimaryKeyHeader() async throws {
        guard let primaryKey = ParseSwift.configuration.primaryKey else {
            throw ParseError(code: .otherCause, message: "Parse configuration should contain key")
        }

        let headers = try await API.getHeaders(options: [])
        XCTAssertNil(headers["X-Parse-Master-Key"])

        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch await post.prepareURLRequest(options: [.usePrimaryKey]) {

        case .success(let request):
            XCTAssertEqual(request.allHTTPHeaderFields?["X-Parse-Master-Key"],
                           primaryKey)
            XCTAssertEqual(ParseSwift.configuration.primaryKey,
                           primaryKey)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testSessionTokenHeader() async throws {
        await userLogin()
        guard let sessionToken = await BaseParseUser.currentContainer()?.sessionToken else {
            throw ParseError(code: .otherCause, message: "Parse current user should have session token")
        }

        let headers = try await API.getHeaders(options: [])
        XCTAssertEqual(headers["X-Parse-Session-Token"], sessionToken)

        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch await post.prepareURLRequest(options: []) {

        case .success(let request):
            XCTAssertEqual(request.allHTTPHeaderFields?["X-Parse-Session-Token"],
                           sessionToken)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testReplaceSessionTokenHeader() async throws {

        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch await post.prepareURLRequest(options: [.sessionToken("hello")]) {

        case .success(let request):
            XCTAssertEqual(request.allHTTPHeaderFields?["X-Parse-Session-Token"],
                           "hello")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testInstallationIdHeader() async throws {
        guard let installationId = await BaseParseInstallation.currentContainer().installationId else {
            throw ParseError(code: .otherCause, message: "Parse current user should have session token")
        }

        let headers = try await API.getHeaders(options: [])
        XCTAssertEqual(headers["X-Parse-Installation-Id"], installationId)

        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch await post.prepareURLRequest(options: []) {

        case .success(let request):
            XCTAssertEqual(request.allHTTPHeaderFields?["X-Parse-Installation-Id"],
                           installationId)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testReplaceInstallationIdHeader() async throws {
        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch await post.prepareURLRequest(options: [.installationId("hello")]) {

        case .success(let request):
            XCTAssertEqual(request.allHTTPHeaderFields?["X-Parse-Installation-Id"],
                           "hello")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testContentHeader() async throws {
        let headers = try await API.getHeaders(options: [])
        XCTAssertEqual(headers["Content-Type"], "application/json")

        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch await post.prepareURLRequest(options: []) {

        case .success(let request):
            XCTAssertEqual(request.allHTTPHeaderFields?["Content-Type"],
                           "application/json")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testReplaceContentHeader() async throws {
        let headers = try await API.getHeaders(options: [])
        XCTAssertEqual(headers["Content-Type"], "application/json")

        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch await post.prepareURLRequest(options: [.mimeType("application/html")]) {

        case .success(let request):
            XCTAssertEqual(request.allHTTPHeaderFields?["Content-Type"],
                           "application/html")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testContentLengthHeader() async throws {
        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch await post.prepareURLRequest(options: [.fileSize("512")]) {

        case .success(let request):
            XCTAssertEqual(request.allHTTPHeaderFields?["Content-Length"],
                           "512")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testRemoveContentHeader() async throws {
        let headers = try await API.getHeaders(options: [])
        XCTAssertEqual(headers["Content-Type"], "application/json")

        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch await post.prepareURLRequest(options: [.removeMimeType]) {

        case .success(let request):
            XCTAssertNil(request.allHTTPHeaderFields?["Content-Type"])
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testClientVersionAPIMethod() {
        let clientVersion = API.clientVersion()
        XCTAssertTrue(clientVersion.contains(ParseConstants.sdk))
        XCTAssertTrue(clientVersion.contains(ParseConstants.version))

        let splitString = clientVersion
            .components(separatedBy: ParseConstants.sdk)
        XCTAssertEqual(splitString.count, 2)
        // If successful, will remove `swift` resulting in ""
        XCTAssertEqual(splitString[0], "")
        XCTAssertEqual(splitString[1], ParseConstants.version)

        // Test incorrect split
        let splitString2 = clientVersion
            .components(separatedBy: "hello")
        XCTAssertEqual(splitString2.count, 1)
        XCTAssertEqual(splitString2[0], clientVersion)
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func testClientVersionHeader() async throws {
        let headers = try await API.getHeaders(options: [])
        XCTAssertEqual(headers["X-Parse-Client-Version"], API.clientVersion())

        let post = API.Command<Level, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }
        switch await post.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Client-Version"] != API.clientVersion() {
                XCTFail("Should contain correct Client Version header")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }

        let put = API.Command<Level, NoBody?>(method: .PUT, path: .login) { _ in
            return nil
        }
        switch await put.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Client-Version"] != API.clientVersion() {
                XCTFail("Should contain correct Client Version header")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }

        let patch = API.Command<Level, NoBody?>(method: .PATCH, path: .login) { _ in
            return nil
        }
        switch await patch.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Client-Version"] != API.clientVersion() {
                XCTFail("Should contain correct Client Version header")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }

        let delete = API.Command<Level, NoBody?>(method: .DELETE, path: .login) { _ in
            return nil
        }
        switch await delete.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Client-Version"] != API.clientVersion() {
                XCTFail("Should contain correct Client Version header")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }

        let get = API.Command<Level, NoBody?>(method: .GET, path: .login) { _ in
            return nil
        }
        switch await get.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Client-Version"] != API.clientVersion() {
                XCTFail("Should contain correct Client Version header")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func testIdempodency() async throws {
        let headers = try await API.getHeaders(options: [])
        XCTAssertNotNil(headers["X-Parse-Request-Id"])

        let post = API.Command<Level, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }
        switch await post.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Request-Id"] == nil {
                XCTFail("Should contain idempotent header ID")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }

        let put = API.Command<Level, NoBody?>(method: .PUT, path: .login) { _ in
            return nil
        }
        switch await put.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Request-Id"] == nil {
                XCTFail("Should contain idempotent header ID")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }

        let patch = API.Command<Level, NoBody?>(method: .PATCH, path: .login) { _ in
            return nil
        }
        switch await patch.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Request-Id"] == nil {
                XCTFail("Should contain idempotent header ID")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }

        let delete = API.Command<Level, NoBody?>(method: .DELETE, path: .login) { _ in
            return nil
        }
        switch await delete.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Request-Id"] != nil {
                XCTFail("Should not contain idempotent header ID")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }

        let get = API.Command<Level, NoBody?>(method: .GET, path: .login) { _ in
            return nil
        }
        switch await get.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Request-Id"] != nil {
                XCTFail("Should not contain idempotent header ID")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func testIdempodencyNoParseBody() async throws {
        let headers = try await API.getHeaders(options: [])
        XCTAssertNotNil(headers["X-Parse-Request-Id"])

        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }
        switch await post.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Request-Id"] == nil {
                XCTFail("Should contain idempotent header ID")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }

        let put = API.NonParseBodyCommand<NoBody, NoBody?>(method: .PUT, path: .login) { _ in
            return nil
        }
        switch await put.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Request-Id"] == nil {
                XCTFail("Should contain idempotent header ID")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }

        let patch = API.NonParseBodyCommand<NoBody, NoBody?>(method: .PATCH, path: .login) { _ in
            return nil
        }
        switch await patch.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Request-Id"] == nil {
                XCTFail("Should contain idempotent header ID")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }

        let delete = API.NonParseBodyCommand<NoBody, NoBody?>(method: .DELETE, path: .login) { _ in
            return nil
        }
        switch await delete.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Request-Id"] != nil {
                XCTFail("Should not contain idempotent header ID")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }

        let get = API.NonParseBodyCommand<NoBody, NoBody?>(method: .GET, path: .login) { _ in
            return nil
        }
        switch await get.prepareURLRequest(options: []) {

        case .success(let request):
            if request.allHTTPHeaderFields?["X-Parse-Request-Id"] != nil {
                XCTFail("Should not contain idempotent header ID")
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testMetaDataHeader() async throws {
        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch await post.prepareURLRequest(options: [.metadata(["hello": "world"])]) {

        case .success(let request):
            XCTAssertEqual(request.allHTTPHeaderFields?["hello"], "world")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testTagsHeader() async throws {
        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch await post.prepareURLRequest(options: [.tags(["hello": "world"])]) {

        case .success(let request):
            XCTAssertEqual(request.allHTTPHeaderFields?["hello"], "world")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testContextHeader() async throws {
        let headers = try await API.getHeaders(options: [])
        XCTAssertNil(headers["X-Parse-Cloud-Context"])

        let post = API.NonParseBodyCommand<NoBody, NoBody?>(method: .POST, path: .login) { _ in
            return nil
        }

        switch await post.prepareURLRequest(options: [.context(["hello": "world"])]) {

        case .success(let request):
            XCTAssertEqual(request.allHTTPHeaderFields?["X-Parse-Cloud-Context"], "{\"hello\":\"world\"}")
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    func testComputeDelayFromString() {
        let dateString = "Wed, 21 Oct 2015 07:28:00 GMT"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, d MMM yyyy HH:mm:ss z"
        guard let date = dateFormatter.date(from: dateString),
            let computedDate = Utility.computeDelay(dateString) else {
            XCTFail("Should have produced date")
            return
        }
        XCTAssertLessThan(date.timeIntervalSinceNow - computedDate, 1)
    }
}
