//
//  ParseSessionTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/17/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

import XCTest
@testable import ParseSwift

class ParseSessionTests: XCTestCase {

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
    }

    struct Session<SessionUser: ParseUser>: ParseSession {

        var sessionToken: String
        var user: ParseSessionTests.User
        var restricted: Bool?
        var createdWith: [String: String]
        var installationId: String
        var expiresAt: Date
        var originalData: Data?

        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        init() {
            sessionToken = "hello"
            user = User()
            restricted = false
            createdWith = ["yolo": "yaw"]
            installationId = "yes"
            expiresAt = Date()
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
                                        testing: false) // Set to false for codecov

    }

    override func tearDown() async throws {
        try await super.tearDown()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try await KeychainStore.shared.deleteAll()
        #endif
        try await ParseStorage.shared.deleteAll()
        Parse.configuration = nil
    }

    func testFetchCommand() throws {
        var session = Session<User>()
        XCTAssertThrowsError(try session.fetchCommand(include: nil))
        session.objectId = "me"
        do {
            let command = try session.fetchCommand(include: nil)
            XCTAssertNotNil(command)
            // Generates this component because fetchCommand is at the Objective protocol level
            XCTAssertEqual(command.path.urlComponent, "/sessions/me")
            XCTAssertEqual(command.method, API.Method.GET)
            XCTAssertNil(command.params)
            XCTAssertNil(command.body)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testEndPoint() throws {
        var session = Session<User>()
        XCTAssertEqual(session.endpoint.urlComponent, "/sessions")
        session.objectId = "me"
        XCTAssertEqual(session.endpoint.urlComponent, "/sessions/me")
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func testParseURLSession() throws {
        XCTAssertEqual(URLSession.parse.configuration.requestCachePolicy,
                       ParseSwift.configuration.requestCachePolicy)
        XCTAssertEqual(URLSession.parse.configuration.httpAdditionalHeaders?.count,
                       ParseSwift.configuration.httpAdditionalHeaders?.count)
        guard let delegate = URLSession.parse.delegate as? ParseURLSessionDelegate else {
            XCTFail("Should have casted")
            return
        }
        XCTAssertEqual(delegate, Parse.sessionDelegate)
    }

    func testParseURLSessionDefaultCertificatePinning() throws {
        let expectation1 = XCTestExpectation(description: "Authentication")
        URLSession.parse.delegate?.urlSession?(URLSession.parse,
                                               didReceive: .init()) { (challenge, credential) in
            XCTAssertEqual(challenge, .performDefaultHandling)
            XCTAssertNil(credential)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 10.0)
    }

    func testParseURLSessionCustomCertificatePinning() async throws {
        guard let url = URL(string: "http://localhost:1337/parse") else {
            XCTFail("Should create valid URL")
            return
        }
        try await ParseSwift.initialize(applicationId: "applicationId",
                                        clientKey: "clientKey",
                                        primaryKey: "primaryKey",
                                        serverURL: url,
                                        // swiftlint:disable:next line_length
                                        testing: false) {(_: URLAuthenticationChallenge, completion: (_: URLSession.AuthChallengeDisposition, _: URLCredential?) -> Void) in
            completion(.cancelAuthenticationChallenge, .none)
        }

        guard let delegate = URLSession.parse.delegate else {
            XCTFail("Should have unwrapped")
            return
        }

        let session = await delegate.urlSession!(URLSession.parse,
                                                 didReceive: .init())
        XCTAssertEqual(session.0, .cancelAuthenticationChallenge)
        XCTAssertEqual(session.1, .none)
    }

    func testParseURLSessionUpdateCertificatePinning() throws {
        // swiftlint:disable:next line_length
        ParseSwift.updateAuthentication({(_: URLAuthenticationChallenge, completion: (_: URLSession.AuthChallengeDisposition, _: URLCredential?) -> Void) in
            completion(.cancelAuthenticationChallenge, .none)
        })
        let expectation1 = XCTestExpectation(description: "Authentication")
        URLSession.parse.delegate?.urlSession?(URLSession.parse,
                                               didReceive: .init()) { (challenge, credential) in
            XCTAssertEqual(challenge, .cancelAuthenticationChallenge)
            XCTAssertEqual(credential, .none)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 10.0)
    }
    #endif
}
