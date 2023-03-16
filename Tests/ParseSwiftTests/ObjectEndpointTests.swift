//
//  ObjectEndpointTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 3/15/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import XCTest
import ParseSwift

class ObjectEndpointTests: XCTestCase {
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

    struct Installation: ParseInstallation {
        var installationId: String?
        var deviceType: String?
        var deviceToken: String?
        var badge: Int?
        var timeZone: String?
        var channels: [String]?
        var appName: String?
        var appIdentifier: String?
        var appVersion: String?
        var parseVersion: String?
        var localeIdentifier: String?
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?
        var customKey: String?
    }

    struct Session<SessionUser: ParseUser>: ParseSession {

        var sessionToken: String
        var user: User
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

    struct Role<RoleUser: ParseUser>: ParseRole {

        // required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        // provided by Role
        var name: String?
    }

    func testUser() async throws {
        let objectId = "yarr"
        var user = User()

        XCTAssertEqual(user.endpoint.urlComponent, "/users")
        user.objectId = objectId
        XCTAssertEqual(user.endpoint.urlComponent, "/users/\(objectId)")
    }

    func testInstallation() async throws {
        let objectId = "yarr"
        var installation = Installation()

        XCTAssertEqual(installation.endpoint.urlComponent, "/installations")
        installation.objectId = objectId
        XCTAssertEqual(installation.endpoint.urlComponent, "/installations/\(objectId)")
    }

    func testSession() throws {
        var session = Session<User>()
        XCTAssertEqual(session.endpoint.urlComponent, "/sessions")
        session.objectId = "me"
        XCTAssertEqual(session.endpoint.urlComponent, "/sessions/me")
    }

    func testRole() throws {
        var role = try Role<User>(name: "Administrator")
        XCTAssertEqual(role.endpoint.urlComponent, "/roles")
        role.objectId = "me"
        XCTAssertEqual(role.endpoint.urlComponent, "/roles/me")
    }
}
