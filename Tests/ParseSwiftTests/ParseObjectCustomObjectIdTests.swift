//
//  ParseObjectCustomObjectIdTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 3/20/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseObjectCustomObjectIdTests: XCTestCase, @unchecked Sendable { // swiftlint:disable:this type_body_length
    struct Level: ParseObject {
        var objectId: String?

        var createdAt: Date?

        var updatedAt: Date?

        var ACL: ParseACL?

        var originalData: Data?

        var name = "First"
    }

    struct GameScore: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        //: Your own properties
        var points: Int?
        var player: String?
        var level: Level?
        var levels: [Level]?

        // custom initializers
        init() {}
        init (objectId: String?) {
            self.objectId = objectId
        }
        init(points: Int) {
            self.points = points
            self.player = "Jen"
        }
        init(points: Int, name: String) {
            self.points = points
            self.player = name
        }
    }

    struct Game: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        //: Your own properties
        var gameScore: GameScore
        var gameScores = [GameScore]()
        var name = "Hello"
        var profilePicture: ParseFile?

        //: a custom initializer
        init() {
            self.gameScore = GameScore()
        }
        init(gameScore: GameScore) {
            self.gameScore = gameScore
        }
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
                                        requiringCustomObjectIds: true,
                                        testing: true)
    }

    override func tearDown() async throws {
        try await super.tearDown()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        try KeychainStore.shared.deleteAll()
        #endif
        try await ParseStorage.shared.deleteAll()

        guard let fileManager = ParseFileManager() else {
            throw ParseError(code: .otherCause, message: "Should have initialized file manage")
        }

        let directory2 = try ParseFileManager.downloadDirectory()
        try? fileManager.removeDirectoryContents(directory2)
    }

    func testSaveCommand() async throws {
        let objectId = "yarr"
        var score = GameScore(points: 10)
        score.objectId = objectId
        let className = score.className

        let command = try await score.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/classes/\(className)")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)

        guard let body = command.body else {
            XCTFail("Should be able to unwrap")
            return
        }

        let expected = "{\"objectId\":\"yarr\",\"player\":\"Jen\",\"points\":10}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testSaveUpdateCommand() async throws {
        var score = GameScore(points: 10)
        let className = score.className
        let objectId = "yarr"
        score.objectId = objectId
        score.createdAt = Date()
        score.updatedAt = score.createdAt

        let command = try await score.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/classes/\(className)/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)

        guard let body = command.body else {
            XCTFail("Should be able to unwrap")
            return
        }

        let expected = "{\"objectId\":\"yarr\",\"player\":\"Jen\",\"points\":10}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testSaveAllCommand() async throws {
        var score = GameScore(points: 10)
        score.objectId = "yarr"
        var score2 = GameScore(points: 20)
        score2.objectId = "yolo"

        let objects = [score, score2]
        var commands = [API.Command<GameScore, GameScore>]()
        for object in objects {
            let command = try await object.saveCommand()
            commands.append(command)
        }
        let body = BatchCommand(requests: commands, transaction: false)
        // swiftlint:disable:next line_length
        let expected = "{\"requests\":[{\"body\":{\"objectId\":\"yarr\",\"player\":\"Jen\",\"points\":10},\"method\":\"POST\",\"path\":\"\\/classes\\/GameScore\"},{\"body\":{\"objectId\":\"yolo\",\"player\":\"Jen\",\"points\":20},\"method\":\"POST\",\"path\":\"\\/classes\\/GameScore\"}],\"transaction\":false}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body,
                    batching: true,
                    collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testUpdateAllCommand() async throws {
        var score = GameScore(points: 10)
        score.objectId = "yarr"
        score.createdAt = Date()
        var score2 = GameScore(points: 20)
        score2.objectId = "yolo"
        score2.createdAt = Date()

        let objects = [score, score2]
        var commands = [API.Command<GameScore, GameScore>]()
        for object in objects {
            let command = try await object.saveCommand()
            commands.append(command)
        }
        let body = BatchCommand(requests: commands, transaction: false)
        // swiftlint:disable:next line_length
        let expected = "{\"requests\":[{\"body\":{\"objectId\":\"yarr\",\"player\":\"Jen\",\"points\":10},\"method\":\"PUT\",\"path\":\"\\/classes\\/GameScore\\/yarr\"},{\"body\":{\"objectId\":\"yolo\",\"player\":\"Jen\",\"points\":20},\"method\":\"PUT\",\"path\":\"\\/classes\\/GameScore\\/yolo\"}],\"transaction\":false}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body,
                    batching: true,
                    collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testUserSaveCommand() async throws {
        let objectId = "yarr"
        var user = User()
        user.objectId = objectId

        let command = try await user.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)

        guard let body = command.body else {
            XCTFail("Should be able to unwrap")
            return
        }

        let expected = "{\"objectId\":\"yarr\"}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testUserUpdateCommand() async throws {
        let objectId = "yarr"
        var user = User()
        user.objectId = objectId
        user.createdAt = Date()

        let command = try await user.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/users/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)

        guard let body = command.body else {
            XCTFail("Should be able to unwrap")
            return
        }

        let expected = "{\"objectId\":\"yarr\"}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testUserSaveAllCommand() async throws {
        var user = User()
        user.objectId = "yarr"
        var user2 = User()
        user2.objectId = "yolo"

        let objects = [user, user2]
        var commands = [API.Command<User, User>]()
        for object in objects {
            let command = try await object.saveCommand()
            commands.append(command)
        }
        let body = BatchCommand(requests: commands, transaction: false)
        // swiftlint:disable:next line_length
        let expected = "{\"requests\":[{\"body\":{\"objectId\":\"yarr\"},\"method\":\"POST\",\"path\":\"\\/users\"},{\"body\":{\"objectId\":\"yolo\"},\"method\":\"POST\",\"path\":\"\\/users\"}],\"transaction\":false}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body,
                    batching: true,
                    collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testUserUpdateAllCommand() async throws {
        var user = User()
        user.objectId = "yarr"
        user.createdAt = Date()
        var user2 = User()
        user2.objectId = "yolo"
        user2.createdAt = Date()

        let objects = [user, user2]
        var commands = [API.Command<User, User>]()
        for object in objects {
            let command = try await object.saveCommand()
            commands.append(command)
        }
        let body = BatchCommand(requests: commands, transaction: false)
        // swiftlint:disable:next line_length
        let expected = "{\"requests\":[{\"body\":{\"objectId\":\"yarr\"},\"method\":\"PUT\",\"path\":\"\\/users\\/yarr\"},{\"body\":{\"objectId\":\"yolo\"},\"method\":\"PUT\",\"path\":\"\\/users\\/yolo\"}],\"transaction\":false}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body,
                    batching: true,
                    collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testInstallationSaveCommand() async throws {
        let objectId = "yarr"
        var installation = Installation()
        installation.objectId = objectId

        let command = try await installation.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/installations")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)

        guard let body = command.body else {
            XCTFail("Should be able to unwrap")
            return
        }

        let expected = "{\"objectId\":\"yarr\"}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testInstallationUpdateCommand() async throws {
        let objectId = "yarr"
        var installation = Installation()
        installation.objectId = objectId
        installation.createdAt = Date()

        let command = try await installation.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/installations/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)

        guard let body = command.body else {
            XCTFail("Should be able to unwrap")
            return
        }

        let expected = "{\"objectId\":\"yarr\"}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body, collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testInstallationSaveAllCommand() async throws {
        var installation = Installation()
        installation.objectId = "yarr"
        var installation2 = Installation()
        installation2.objectId = "yolo"

        let objects = [installation, installation2]
        var commands = [API.Command<Installation, Installation>]()
        for object in objects {
            let command = try await object.saveCommand()
            commands.append(command)
        }
        let body = BatchCommand(requests: commands, transaction: false)
        // swiftlint:disable:next line_length
        let expected = "{\"requests\":[{\"body\":{\"objectId\":\"yarr\"},\"method\":\"POST\",\"path\":\"\\/installations\"},{\"body\":{\"objectId\":\"yolo\"},\"method\":\"POST\",\"path\":\"\\/installations\"}],\"transaction\":false}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body,
                    batching: true,
                    collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testInstallationUpdateAllCommand() async throws {
        var installation = Installation()
        installation.objectId = "yarr"
        installation.createdAt = Date()
        var installation2 = Installation()
        installation2.objectId = "yolo"
        installation2.createdAt = Date()

        let objects = [installation, installation2]
        var commands = [API.Command<Installation, Installation>]()
        for object in objects {
            let command = try await object.saveCommand()
            commands.append(command)
        }
        let body = BatchCommand(requests: commands, transaction: false)
        // swiftlint:disable:next line_length
        let expected = "{\"requests\":[{\"body\":{\"objectId\":\"yarr\"},\"method\":\"PUT\",\"path\":\"\\/installations\\/yarr\"},{\"body\":{\"objectId\":\"yolo\"},\"method\":\"PUT\",\"path\":\"\\/installations\\/yolo\"}],\"transaction\":false}"
        let encoded = try ParseCoding.parseEncoder()
            .encode(body,
                    batching: true,
                    collectChildren: false,
                    objectsSavedBeforeThisOne: nil,
                    filesSavedBeforeThisOne: nil).encoded
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testSaveCommandNoObjectId() async throws {
        let score = GameScore(points: 10)
        do {
            _ = try await score.saveCommand()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.containedIn([.missingObjectId]))
        }
    }

    func testSaveCommandNoObjectIdIgnoreConfig() async throws {
        let score = GameScore(points: 10)
        _ = try await score.saveCommand(ignoringCustomObjectIdConfig: true)
    }

    func testUpdateCommandNoObjectId() async throws {
        var score = GameScore(points: 10)
        score.createdAt = Date()
        do {
            _ = try await score.saveCommand()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.containedIn([.missingObjectId]))
        }
    }

    func testUpdateCommandNoObjectIdIgnoreConfig() async throws {
        var score = GameScore(points: 10)
        score.createdAt = Date()
        _ = try await score.saveCommand(ignoringCustomObjectIdConfig: true)
    }

    func testSaveAllNoObjectIdCommand() async throws {
        let score = GameScore(points: 10)
        let score2 = GameScore(points: 20)
        let objects = [score, score2]
        do {
            try await objects.saveAll()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }
    }

    func testUpdateAllNoObjectIdCommand() async throws {
        var score = GameScore(points: 10)
        score.createdAt = Date()
        var score2 = GameScore(points: 20)
        score2.createdAt = Date()
        let objects = [score, score2]
        do {
            try await objects.saveAll()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }
    }

    func testUserSaveCommandNoObjectId() async throws {
        let user = User()
        do {
            _ = try await user.saveCommand()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }
    }

    func testUserSaveCommandNoObjectIdIgnoreConfig() async throws {
        let user = User()
        _ = try await user.saveCommand(ignoringCustomObjectIdConfig: true)
    }

    func testUserUpdateCommandNoObjectId() async throws {
        var user = User()
        user.createdAt = Date()
        do {
            _ = try await user.saveCommand()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }
    }

    func testUserUpdateCommandNoObjectIdIgnoreConfig() async throws {
        var user = User()
        user.createdAt = Date()
        _ = try await user.saveCommand(ignoringCustomObjectIdConfig: true)
    }

    func testUserSaveAllNoObjectIdCommand() async throws {
        let user = User()
        let user2 = User()
        let objects = [user, user2]
        do {
            try await objects.saveAll()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }
    }

    func testUserUpdateAllNoObjectIdCommand() async throws {
        var user = GameScore(points: 10)
        user.createdAt = Date()
        var user2 = GameScore(points: 20)
        user2.createdAt = Date()
        let objects = [user, user2]
        do {
            try await objects.saveAll()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }
    }

    func testInstallationSaveCommandNoObjectId() async throws {
        let installation = Installation()
        do {
            _ = try await installation.saveCommand()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }
    }

    func testInstallationSaveCommandNoObjectIdIgnoreConfig() async throws {
        let installation = Installation()
        _ = try await installation.saveCommand(ignoringCustomObjectIdConfig: true)
    }

    func testInstallationUpdateCommandNoObjectId() async throws {
        var installation = Installation()
        installation.createdAt = Date()
        do {
            _ = try await installation.saveCommand()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }
    }

    func testInstallationUpdateCommandNoObjectIdIgnoreConfig() async throws {
        var installation = Installation()
        installation.createdAt = Date()
        _ = try await installation.saveCommand(ignoringCustomObjectIdConfig: true)
    }

    func testInstallationSaveAllNoObjectIdCommand() async throws {
        let installation = Installation()
        let installation2 = Installation()
        let objects = [installation, installation2]
        do {
            try await objects.saveAll()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }
    }

    func testInstallationUpdateAllNoObjectIdCommand() async throws {
        var score = GameScore(points: 10)
        score.createdAt = Date()
        var score2 = GameScore(points: 20)
        score2.createdAt = Date()
        let objects = [score, score2]
        do {
            try await objects.saveAll()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }
    }

    func testSave() async throws {
        var score = GameScore(points: 10)
        score.objectId = "yarr"

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(scoreOnServer)
            // Get dates in correct format from ParseDecoding strategy
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        do {
            let saved = try await score.save()
            XCTAssert(saved.hasSameObjectId(as: scoreOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

	func testCreateServerReturnsPointer() async throws {
		var score = GameScore(points: 10)
		score.objectId = "yarr"

		var scoreOnServer = try score.toPointer()

		let encoded: Data!
		do {
			encoded = try ParseCoding.jsonEncoder().encode(scoreOnServer)
			// Get dates in correct format from ParseDecoding strategy
			scoreOnServer = try score.getDecoder().decode(
				Pointer<GameScore>.self,
				from: encoded
			)
		} catch {
			XCTFail("Should encode/decode. Error \(error)")
			return
		}

		MockURLProtocol.mockRequests { _ in
			return MockURLResponse(data: encoded, statusCode: 200)
		}
		do {
			let saved = try await score.create()
			XCTAssertTrue(saved.objectId == scoreOnServer.objectId)
		} catch {
			XCTFail(error.localizedDescription)
		}
	}

	func testCreateServerReturnsIncorrectJSON() async throws {
		var score = GameScore(points: 10)
		score.objectId = "yarr"

		var scoreOnServer = GameScore()

		let encoded: Data!
		do {
			encoded = try ParseCoding.jsonEncoder().encode(scoreOnServer)
			// Get dates in correct format from ParseDecoding strategy
			scoreOnServer = try score.getDecoder().decode(
				GameScore.self,
				from: encoded
			)
		} catch {
			XCTFail("Should encode/decode. Error \(error)")
			return
		}

		MockURLProtocol.mockRequests { _ in
			return MockURLResponse(data: encoded, statusCode: 200)
		}
		do {
			_ = try await score.create()
			XCTFail("Should have failed to decode")
		} catch {
			XCTAssertTrue(error.equalsTo(.otherCause))
		}
	}

    func testSaveNoObjectId() async throws {
        let score = GameScore(points: 10)
        do {
            _ = try await score.save()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }
    }

    func testSaveNoObjectIdIgnoreConfig() async throws {
        let score = GameScore(points: 10)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(scoreOnServer)
            // Get dates in correct format from ParseDecoding strategy
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        do {
            let saved = try await score.save(ignoringCustomObjectIdConfig: true)
            XCTAssert(saved.hasSameObjectId(as: scoreOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUpdate() async throws {
        var score = GameScore(points: 10)
        score.objectId = "yarr"
        score.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.ACL = nil

        var scoreOnServer = score
        scoreOnServer.updatedAt = Date()

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(scoreOnServer)
            // Get dates in correct format from ParseDecoding strategy
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        do {
            let saved = try await score.save()
            XCTAssertTrue(saved.hasSameObjectId(as: scoreOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUpdateNoObjectId() async throws {
        var score = GameScore(points: 10)
        score.createdAt = Date()
        do {
            _ = try await score.save()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }
    }

    func testUpdateNoObjectIdIgnoreConfig() async throws {
        var score = GameScore(points: 10)
        score.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.ACL = nil

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.updatedAt = Date()

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(scoreOnServer)
            // Get dates in correct format from ParseDecoding strategy
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        do {
            let saved = try await score.save(ignoringCustomObjectIdConfig: true)
            XCTAssertTrue(saved.hasSameObjectId(as: scoreOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func saveAsync(score: GameScore,
                   scoreOnServer: GameScore,
                   callbackQueue: DispatchQueue,
                   ignoringCustomObjectIdConfig: Bool = false) {

        let expectation1 = XCTestExpectation(description: "Save object1")

        score.save(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
                   options: [],
                   callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: scoreOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "Save object2")
        score.save(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
                   options: [.usePrimaryKey],
                   callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: scoreOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testSaveAsyncMainQueue() {
        var score = GameScore(points: 10)
        score.objectId = "yarr"

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(scoreOnServer)
            // Get dates in correct format from ParseDecoding strategy
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        self.saveAsync(score: score, scoreOnServer: scoreOnServer, callbackQueue: .main)
    }

    func testSaveNoObjectIdAsyncMainQueue() async throws {
        let score = GameScore(points: 10)
        do {
            _ = try await score.save()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }

        let expectation1 = XCTestExpectation(description: "Save object2")
        score.save { result in
            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("objectId"))
            } else {
                XCTFail("Should have failed")
            }
            expectation1.fulfill()
        }
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testSaveNoObjectIdIgnoreConfigAsyncMainQueue() {
        let score = GameScore(points: 10)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(scoreOnServer)
            // Get dates in correct format from ParseDecoding strategy
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        self.saveAsync(score: score,
                       scoreOnServer: scoreOnServer,
                       callbackQueue: .main,
                       ignoringCustomObjectIdConfig: true)
    }

    func updateAsync(score: GameScore,
                     scoreOnServer: GameScore,
                     ignoringCustomObjectIdConfig: Bool = false,
                     callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Update object1")

        score.save(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
                   options: [],
                   callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                XCTAssertNil(saved.ACL)
                if callbackQueue.qos == .userInteractive {
                    XCTAssertTrue(Thread.isMainThread)
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "Update object2")
        score.save(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
                   options: [.usePrimaryKey],
                   callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                XCTAssertTrue(saved.hasSameObjectId(as: scoreOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testUpdateAsyncMainQueue() {
        var score = GameScore(points: 10)
        score.objectId = "yarr"
        score.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.ACL = nil

        var scoreOnServer = score
        scoreOnServer.updatedAt = Date()
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(scoreOnServer)
            // Get dates in correct format from ParseDecoding strategy
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        self.updateAsync(score: score, scoreOnServer: scoreOnServer, callbackQueue: .main)
    }

    func testUpdateNoObjectIdAsyncMainQueue() async throws {
        var score = GameScore(points: 10)
        score.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        do {
            _ = try await score.save()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }

        let expectation1 = XCTestExpectation(description: "Save object2")
        score.save { result in
            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("objectId"))
            } else {
                XCTFail("Should have failed")
            }
            expectation1.fulfill()
        }
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testUpdateNoObjectIdIgnoreConfigAsyncMainQueue() {
        var score = GameScore(points: 10)
        score.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.ACL = nil

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.updatedAt = Date()
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(scoreOnServer)
            // Get dates in correct format from ParseDecoding strategy
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        self.updateAsync(score: score,
                         scoreOnServer: scoreOnServer,
                         ignoringCustomObjectIdConfig: true,
                         callbackQueue: .main)
    }

    func testSaveAll() async throws {
        var score = GameScore(points: 10)
        score.objectId = "yarr"
        var score2 = GameScore(points: 20)
        score2.objectId = "yolo"

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.ACL = nil

        var scoreOnServer2 = score2
        scoreOnServer2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        scoreOnServer2.ACL = nil

        let response = [BatchResponseItem<GameScore>(success: scoreOnServer, error: nil),
        BatchResponseItem<GameScore>(success: scoreOnServer2, error: nil)]
        let encoded: Data!
        do {
           encoded = try scoreOnServer.getJSONEncoder().encode(response)
           // Get dates in correct format from ParseDecoding strategy
           let encoded1 = try ParseCoding.jsonEncoder().encode(scoreOnServer)
           scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded1)
           let encoded2 = try ParseCoding.jsonEncoder().encode(scoreOnServer2)
           scoreOnServer2 = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded2)

        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200)
        }

        do {

            let saved = try await [score, score2].saveAll()

            XCTAssertEqual(saved.count, 2)
            switch saved[0] {

            case .success(let first):
                XCTAssert(first.hasSameObjectId(as: scoreOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):
                XCTAssert(second.hasSameObjectId(as: scoreOnServer2))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveAllNoObjectId() async throws {
        let score = GameScore(points: 10)
        let score2 = GameScore(points: 20)
        do {
            try await [score, score2].saveAll()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }
    }

    func testSaveAllNoObjectIdIgnoreConfig() async throws {
        let score = GameScore(points: 10)
        let score2 = GameScore(points: 20)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.ACL = nil

        var scoreOnServer2 = score2
        scoreOnServer2.objectId = "yolo"
        scoreOnServer2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        scoreOnServer2.ACL = nil

        let response = [BatchResponseItem<GameScore>(success: scoreOnServer, error: nil),
        BatchResponseItem<GameScore>(success: scoreOnServer2, error: nil)]
        let encoded: Data!
        do {
           encoded = try scoreOnServer.getJSONEncoder().encode(response)
           // Get dates in correct format from ParseDecoding strategy
           let encoded1 = try ParseCoding.jsonEncoder().encode(scoreOnServer)
           scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded1)
           let encoded2 = try ParseCoding.jsonEncoder().encode(scoreOnServer2)
           scoreOnServer2 = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded2)

        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200)
        }

        do {

            let saved = try await [score, score2].saveAll(ignoringCustomObjectIdConfig: true)

            XCTAssertEqual(saved.count, 2)
            switch saved[0] {

            case .success(let first):
                XCTAssert(first.hasSameObjectId(as: scoreOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):
                XCTAssert(second.hasSameObjectId(as: scoreOnServer2))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveAllNoObjectIdAsync() async throws {
        let score = GameScore(points: 10)
        let score2 = GameScore(points: 20)

		do {
			_ = try await [score, score2].saveAll()
			XCTFail("Should have failed")
		} catch let error as ParseError {
			XCTAssertTrue(error.message.contains("objectId"))
		} catch {
			XCTFail("Should have thrown a ParseError")
		}
    }

    func testUpdateAll() async throws {
        var score = GameScore(points: 10)
        score.objectId = "yarr"
        score.createdAt = Date()
        var score2 = GameScore(points: 20)
        score2.objectId = "yolo"
        score2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

        var scoreOnServer = score
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        var scoreOnServer2 = score2
        scoreOnServer2.updatedAt = scoreOnServer2.createdAt
        scoreOnServer2.ACL = nil

        let response = [BatchResponseItem<GameScore>(success: scoreOnServer, error: nil),
        BatchResponseItem<GameScore>(success: scoreOnServer2, error: nil)]
        let encoded: Data!
        do {
           encoded = try scoreOnServer.getJSONEncoder().encode(response)
           // Get dates in correct format from ParseDecoding strategy
           let encoded1 = try ParseCoding.jsonEncoder().encode(scoreOnServer)
           scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded1)
           let encoded2 = try ParseCoding.jsonEncoder().encode(scoreOnServer2)
           scoreOnServer2 = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded2)

        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200)
        }

        do {

            let saved = try await [score, score2].saveAll()

            XCTAssertEqual(saved.count, 2)
            switch saved[0] {

            case .success(let first):
                XCTAssert(first.hasSameObjectId(as: scoreOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):
                XCTAssert(second.hasSameObjectId(as: scoreOnServer2))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUpdateAllNoObjectId() async throws {
        var score = GameScore(points: 10)
        score.createdAt = Date()
        var score2 = GameScore(points: 20)
        score2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        do {
            try await [score, score2].saveAll()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }
    }

    func testUpdateAllNoObjectIdAsync() async throws {
        var score = GameScore(points: 10)
        score.createdAt = Date()
        var score2 = GameScore(points: 20)
        score2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

		do {
			_ = try await [score, score2].saveAll()
			XCTFail("Should have failed")
        } catch let error as ParseError {
			XCTAssertTrue(error.message.contains("objectId"))
		} catch {
			XCTFail("Should have throwm a ParseError")
		}
    }

    func testUserSave() async throws {
        var user = User()
        user.objectId = "yarr"
        user.ACL = nil

        var userOnServer = user
        userOnServer.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        do {
            let saved = try await user.save()
            XCTAssert(saved.hasSameObjectId(as: userOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

	func testUserCreateServerReturnsPointer() async throws {
		var user = User()
		user.objectId = "yarr"
		user.ACL = nil

		var userOnServer = try user.toPointer()

		let encoded: Data!
		do {
			encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
			// Get dates in correct format from ParseDecoding strategy
			userOnServer = try user.getDecoder().decode(
				Pointer<User>.self,
				from: encoded
			)
		} catch {
			XCTFail("Should encode/decode. Error \(error)")
			return
		}

		MockURLProtocol.mockRequests { _ in
			return MockURLResponse(data: encoded, statusCode: 200)
		}
		do {
			let saved = try await user.create()
			XCTAssertTrue(saved.objectId == userOnServer.objectId)
		} catch {
			XCTFail(error.localizedDescription)
		}
	}

	func testUserCreateServerReturnsIncorrectJSON() async throws {
		var user = User()
		user.objectId = "yarr"
		user.ACL = nil

		var userOnServer = User()

		let encoded: Data!
		do {
			encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
			// Get dates in correct format from ParseDecoding strategy
			userOnServer = try user.getDecoder().decode(
				User.self,
				from: encoded
			)
		} catch {
			XCTFail("Should encode/decode. Error \(error)")
			return
		}

		MockURLProtocol.mockRequests { _ in
			return MockURLResponse(data: encoded, statusCode: 200)
		}
		do {
			_ = try await user.create()
			XCTFail("Should have failed to decode")
		} catch {
			XCTAssertTrue(error.equalsTo(.otherCause))
		}
	}

    func testUserSaveNoObjectId() async throws {
        let score = GameScore(points: 10)
        do {
            _ = try await score.save()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }
    }

    func testUserSaveNoObjectIdIgnoreConfig() async throws {
        var user = User()
        user.ACL = nil

        var userOnServer = user
        userOnServer.objectId = "yarr"
        userOnServer.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        do {
            let saved = try await user.save(ignoringCustomObjectIdConfig: true)
            XCTAssert(saved.hasSameObjectId(as: userOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUserUpdate() async throws {
        var user = User()
        user.objectId = "yarr"
        user.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        user.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        user.ACL = nil

        var userOnServer = user
        userOnServer.updatedAt = Date()

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        do {
            let saved = try await user.save()
            XCTAssertTrue(saved.hasSameObjectId(as: userOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUserUpdateNoObjectId() async throws {
        var user = User()
        user.createdAt = Date()
        do {
            _ = try await user.save()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }
    }

    func testUserUpdateNoObjectIdIgnoreConfig() async throws {
        var user = User()
        user.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        user.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        user.ACL = nil

        var userOnServer = user
        userOnServer.objectId = "yarr"
        userOnServer.updatedAt = Date()

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        do {
            let saved = try await user.save(ignoringCustomObjectIdConfig: true)
            XCTAssertTrue(saved.hasSameObjectId(as: userOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func saveUserAsync(user: User, userOnServer: User,
                       ignoringCustomObjectIdConfig: Bool = false,
                       callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Update object1")

        user.save(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
                  options: [],
                  callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                XCTAssertTrue(saved.hasSameObjectId(as: userOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testUserSaveAsyncMainQueue() {
        var user = User()
        user.objectId = "yarr"
        user.ACL = nil

        var userOnServer = user
        userOnServer.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        self.saveUserAsync(user: user, userOnServer: userOnServer, callbackQueue: .main)
    }

    func testUserSaveNoObjectIdAsyncMainQueue() async throws {
        let user = User()
        do {
            _ = try await user.save()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }

        let expectation1 = XCTestExpectation(description: "Save object2")
        user.save { result in
            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("objectId"))
            } else {
                XCTFail("Should have failed")
            }
            expectation1.fulfill()
        }
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testUserSaveNoObjectIdIgnoreConfigAsyncMainQueue() {
        var user = User()
        user.ACL = nil

        var userOnServer = user
        userOnServer.objectId = "yarr"
        userOnServer.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        self.saveUserAsync(user: user,
                           userOnServer: userOnServer,
                           ignoringCustomObjectIdConfig: true,
                           callbackQueue: .main)
    }

    func updateUserAsync(user: User, userOnServer: User,
                         ignoringCustomObjectIdConfig: Bool = false,
                         callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Update object1")

        user.save(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                XCTAssertTrue(saved.hasSameObjectId(as: userOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testUserUpdateAsyncMainQueue() {
        var user = User()
        user.objectId = "yarr"
        user.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        user.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        user.ACL = nil

        var userOnServer = user
        userOnServer.updatedAt = Date()
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        self.updateUserAsync(user: user, userOnServer: userOnServer, callbackQueue: .main)
    }

    func testUserUpdateNoObjectIdAsyncMainQueue() async throws {
        var user = User()
        user.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        do {
            _ = try await user.save()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }

        let expectation1 = XCTestExpectation(description: "Save object2")
        user.save { result in
            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("objectId"))
            } else {
                XCTFail("Should have failed")
            }
            expectation1.fulfill()
        }
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testUserSaveAll() async throws {
        var user = User()
        user.objectId = "yarr"

        var user2 = User()
        user2.objectId = "yolo"

        var userOnServer = user
        userOnServer.createdAt = Date()
        userOnServer.ACL = nil

        var userOnServer2 = user2
        userOnServer2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        userOnServer2.ACL = nil

        let response = [BatchResponseItem<User>(success: userOnServer, error: nil),
        BatchResponseItem<User>(success: userOnServer2, error: nil)]
        let encoded: Data!
        do {
            encoded = try userOnServer.getJSONEncoder().encode(response)
            // Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(userOnServer)
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded1)
            let encoded2 = try ParseCoding.jsonEncoder().encode(userOnServer2)
            userOnServer2 = try userOnServer.getDecoder().decode(User.self, from: encoded2)

        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200)
        }

        do {

            let saved = try await [user, user2].saveAll()

            XCTAssertEqual(saved.count, 2)
            switch saved[0] {

            case .success(let first):
                XCTAssert(first.hasSameObjectId(as: userOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):
                XCTAssert(second.hasSameObjectId(as: userOnServer2))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUserSaveAllNoObjectId() async throws {
        let user = User()
        let user2 = User()
        do {
            try await [user, user2].saveAll()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }
    }

    func testUserSaveAllNoObjectIdAsync() async throws {
        let user = User()
        let user2 = User()

		do {
			_ = try await [user, user2].saveAll()
			XCTFail("Should have failed")
		} catch let error as ParseError {
			XCTAssertTrue(error.message.contains("objectId"))
		} catch {
			XCTFail("Should have thrown a ParseError")
		}
    }

    func testUserUpdateAll() async throws {
        var user = User()
        user.objectId = "yarr"
        user.createdAt = Date()
        var user2 = User()
        user2.objectId = "yolo"
        user2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

        var userOnServer = user
        userOnServer.updatedAt = userOnServer.createdAt
        userOnServer.ACL = nil

        var userOnServer2 = user2
        userOnServer2.updatedAt = userOnServer2.createdAt
        userOnServer2.ACL = nil

        let response = [BatchResponseItem<User>(success: userOnServer, error: nil),
        BatchResponseItem<User>(success: userOnServer2, error: nil)]
        let encoded: Data!
        do {
            encoded = try userOnServer.getJSONEncoder().encode(response)
            // Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(userOnServer)
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded1)
            let encoded2 = try ParseCoding.jsonEncoder().encode(userOnServer2)
            userOnServer2 = try userOnServer.getDecoder().decode(User.self, from: encoded2)

        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200)
        }

        do {

            let saved = try await [user, user2].saveAll()

            XCTAssertEqual(saved.count, 2)
            switch saved[0] {

            case .success(let first):
                XCTAssert(first.hasSameObjectId(as: userOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):
                XCTAssert(second.hasSameObjectId(as: userOnServer2))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUserUpdateAllNoObjectId() async throws {
        var user = User()
        user.createdAt = Date()
        var user2 = User()
        user2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        do {
            try await [user, user2].saveAll()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }
    }

    func testUserUpdateAllNoObjectIdIgnoreConfig() async throws {
        var user = User()
        user.createdAt = Date()
        var user2 = User()
        user2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

        var userOnServer = user
        userOnServer.objectId = "yarr"
        userOnServer.updatedAt = userOnServer.createdAt
        userOnServer.ACL = nil

        var userOnServer2 = user2
        userOnServer2.objectId = "yolo"
        userOnServer2.updatedAt = userOnServer2.createdAt
        userOnServer2.ACL = nil

        let response = [BatchResponseItem<User>(success: userOnServer, error: nil),
        BatchResponseItem<User>(success: userOnServer2, error: nil)]
        let encoded: Data!
        do {
            encoded = try userOnServer.getJSONEncoder().encode(response)
            // Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(userOnServer)
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded1)
            let encoded2 = try ParseCoding.jsonEncoder().encode(userOnServer2)
            userOnServer2 = try userOnServer.getDecoder().decode(User.self, from: encoded2)

        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200)
        }

        do {

            let saved = try await [user, user2].saveAll(ignoringCustomObjectIdConfig: true)

            XCTAssertEqual(saved.count, 2)
            switch saved[0] {

            case .success(let first):
                XCTAssert(first.hasSameObjectId(as: userOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):
                XCTAssert(second.hasSameObjectId(as: userOnServer2))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUserUpdateAllNoObjectIdAsync() async throws {
        var user = User()
        user.createdAt = Date()
        var user2 = User()
        user2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

		do {
			_ = try await [user, user2].saveAll()
			XCTFail("Should have failed")
		} catch let error as ParseError {
			XCTAssertTrue(error.message.contains("objectId"))
		} catch {
			XCTFail("Should have thrown a ParseError")
		}
    }

    func testInstallationSave() async throws {
        var installation = Installation()
        installation.objectId = "yarr"
        installation.ACL = nil

        var installationOnServer = installation
        installationOnServer.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
            // Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        do {
            let saved = try await installation.save()
            XCTAssert(saved.hasSameObjectId(as: installationOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

	func testInstallationCreateServerReturnsPointer() async throws {
		var installation = Installation()
		installation.objectId = "yarr"
		installation.ACL = nil

		var installationOnServer = try installation.toPointer()

		let encoded: Data!
		do {
			encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
			// Get dates in correct format from ParseDecoding strategy
			installationOnServer = try installation.getDecoder().decode(
				Pointer<Installation>.self,
				from: encoded
			)
		} catch {
			XCTFail("Should encode/decode. Error \(error)")
			return
		}

		MockURLProtocol.mockRequests { _ in
			return MockURLResponse(data: encoded, statusCode: 200)
		}
		do {
			let saved = try await installation.create()
			XCTAssertTrue(saved.objectId == installationOnServer.objectId)
		} catch {
			XCTFail(error.localizedDescription)
		}
	}

	func testInstallationCreateServerReturnsIncorrectJSON() async throws {
		var installation = Installation()
		installation.objectId = "yarr"
		installation.ACL = nil

		var installationOnServer = Installation()

		let encoded: Data!
		do {
			encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
			// Get dates in correct format from ParseDecoding strategy
			installationOnServer = try installation.getDecoder().decode(
				Installation.self,
				from: encoded
			)
		} catch {
			XCTFail("Should encode/decode. Error \(error)")
			return
		}

		MockURLProtocol.mockRequests { _ in
			return MockURLResponse(data: encoded, statusCode: 200)
		}
		do {
			_ = try await installation.create()
			XCTFail("Should have failed to decode")
		} catch {
			XCTAssertTrue(error.equalsTo(.otherCause))
		}
	}

    func testInstallationSaveNoObjectId() async throws {
        let score = GameScore(points: 10)
        do {
            _ = try await score.save()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }
    }

    func testInstallationSaveNoObjectIdIgnoreConfig() async throws {
        var installation = Installation()
        installation.ACL = nil

        var installationOnServer = installation
        installationOnServer.objectId = "yarr"
        installationOnServer.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
            // Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        do {
            let saved = try await installation.save(ignoringCustomObjectIdConfig: true)
            XCTAssert(saved.hasSameObjectId(as: installationOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testInstallationUpdate() async throws {
        var installation = Installation()
        installation.objectId = "yarr"
        installation.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.ACL = nil

        var installationOnServer = installation
        installationOnServer.updatedAt = Date()

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
            // Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        do {
            let saved = try await installation.save()
            XCTAssertTrue(saved.hasSameObjectId(as: installationOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testInstallationUpdateNoObjectId() async throws {
        var installation = Installation()
        installation.createdAt = Date()
        do {
            _ = try await installation.save()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }
    }

    func testInstallationUpdateNoObjectIdIgnoreConfig() async throws {
        var installation = Installation()
        installation.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.ACL = nil

        var installationOnServer = installation
        installationOnServer.objectId = "yarr"
        installationOnServer.updatedAt = Date()

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
            // Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        do {
            let saved = try await installation.save(ignoringCustomObjectIdConfig: true)
            XCTAssertTrue(saved.hasSameObjectId(as: installationOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func saveInstallationAsync(installation: Installation,
                               installationOnServer: Installation,
                               ignoringCustomObjectIdConfig: Bool = false,
                               callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Update object1")

        installation.save(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
                          options: [],
                          callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                XCTAssertTrue(saved.hasSameObjectId(as: installationOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }

        let expectation2 = XCTestExpectation(description: "Update object2")
        installation.save(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
                          options: [.usePrimaryKey],
                          callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                XCTAssertTrue(saved.hasSameObjectId(as: installationOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testInstallationSaveAsyncMainQueue() {
        var installation = Installation()
        installation.objectId = "yarr"
        installation.ACL = nil

        var installationOnServer = installation
        installationOnServer.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
            // Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        self.saveInstallationAsync(installation: installation,
                                   installationOnServer: installationOnServer,
                                   ignoringCustomObjectIdConfig: false,
                                   callbackQueue: .main)
    }

    func testInstallationSaveNoObjectIdAsyncMainQueue() async throws {
        let installation = Installation()
        do {
            _ = try await installation.save()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }

        let expectation1 = XCTestExpectation(description: "Save object2")
        installation.save { result in
            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("objectId"))
            } else {
                XCTFail("Should have failed")
            }
            expectation1.fulfill()
        }
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testInstallationSaveNoObjectIdIgnoreConfigAsyncMainQueue() {
        var installation = Installation()
        installation.ACL = nil

        var installationOnServer = installation
        installationOnServer.objectId = "yarr"
        installationOnServer.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
            // Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        self.saveInstallationAsync(installation: installation,
                                   installationOnServer: installationOnServer,
                                   ignoringCustomObjectIdConfig: true,
                                   callbackQueue: .main)
    }

    func updateInstallationAsync(installation: Installation,
                                 installationOnServer: Installation,
                                 ignoringCustomObjectIdConfig: Bool = false,
                                 callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Update object1")

        installation.save(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
                          options: [],
                          callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                XCTAssertTrue(saved.hasSameObjectId(as: installationOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testInstallationUpdateAsyncMainQueue() {
        var installation = Installation()
        installation.objectId = "yarr"
        installation.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.ACL = nil

        var installationOnServer = installation
        installationOnServer.updatedAt = Date()
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
            // Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        self.updateInstallationAsync(installation: installation,
                                     installationOnServer: installationOnServer,
                                     callbackQueue: .main)
    }

    func testInstallationUpdateNoObjectIdAsyncMainQueue() async throws {
        var installation = Installation()
        installation.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        do {
            _ = try await installation.save()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }

        let expectation1 = XCTestExpectation(description: "Save object2")
        installation.save { result in
            if case let .failure(error) = result {
                XCTAssertTrue(error.message.contains("objectId"))
            } else {
                XCTFail("Should have failed")
            }
            expectation1.fulfill()
        }
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testInstallationUpdateNoObjectIdIgnoreConfigAsyncMainQueue() {
        var installation = Installation()
        installation.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.ACL = nil

        var installationOnServer = installation
        installationOnServer.objectId = "yarr"
        installationOnServer.updatedAt = Date()
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
            // Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should have encoded/decoded: Error: \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        self.updateInstallationAsync(installation: installation,
                                     installationOnServer: installationOnServer,
                                     ignoringCustomObjectIdConfig: true,
                                     callbackQueue: .main)
    }

    func testInstallationSaveAll() async throws { // swiftlint:disable:this function_body_length
        var installation = Installation()
        installation.objectId = "yarr"

        var installation2 = Installation()
        installation2.objectId = "yolo"

        var installationOnServer = installation
        installationOnServer.createdAt = Date()
        installationOnServer.ACL = nil

        var installationOnServer2 = installation2
        installationOnServer2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installationOnServer2.ACL = nil

        let response = [BatchResponseItem<Installation>(success: installationOnServer, error: nil),
        BatchResponseItem<Installation>(success: installationOnServer2, error: nil)]
        let encoded: Data!
        do {
            encoded = try installationOnServer.getJSONEncoder().encode(response)
            // Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(installationOnServer)
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded1)
            let encoded2 = try ParseCoding.jsonEncoder().encode(installationOnServer2)
            installationOnServer2 = try installationOnServer.getDecoder().decode(Installation.self, from: encoded2)

        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200)
        }

        do {

            let saved = try await [installation, installation2].saveAll()

            XCTAssertEqual(saved.count, 2)
            switch saved[0] {

            case .success(let first):
                XCTAssert(first.hasSameObjectId(as: installationOnServer))
                guard let savedCreatedAt = first.createdAt,
                    let savedUpdatedAt = first.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(savedCreatedAt, installationOnServer.createdAt)
                XCTAssertEqual(savedUpdatedAt, installationOnServer.createdAt)
                XCTAssertNil(first.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):
                XCTAssert(second.hasSameObjectId(as: installationOnServer2))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testInstallationSaveAllNoObjectId() async throws {
        let installation = Installation()
        let installation2 = Installation()
        do {
            try await [installation, installation2].saveAll()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }
    }

    func testInstallationSaveAllIgnoreConfig() async throws { // swiftlint:disable:this function_body_length
        let installation = Installation()

        let installation2 = Installation()

        var installationOnServer = installation
        installationOnServer.objectId = "yarr"
        installationOnServer.createdAt = Date()
        installationOnServer.ACL = nil

        var installationOnServer2 = installation2
        installationOnServer2.objectId = "yolo"
        installationOnServer2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installationOnServer2.ACL = nil

        let response = [BatchResponseItem<Installation>(success: installationOnServer, error: nil),
        BatchResponseItem<Installation>(success: installationOnServer2, error: nil)]
        let encoded: Data!
        do {
            encoded = try installationOnServer.getJSONEncoder().encode(response)
            // Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(installationOnServer)
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded1)
            let encoded2 = try ParseCoding.jsonEncoder().encode(installationOnServer2)
            installationOnServer2 = try installationOnServer.getDecoder().decode(Installation.self, from: encoded2)

        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200)
        }

        do {

            let saved = try await [installation, installation2].saveAll(ignoringCustomObjectIdConfig: true)

            XCTAssertEqual(saved.count, 2)
            switch saved[0] {

            case .success(let first):
                XCTAssert(first.hasSameObjectId(as: installationOnServer))
                guard let savedCreatedAt = first.createdAt,
                    let savedUpdatedAt = first.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(savedCreatedAt, installationOnServer.createdAt)
                XCTAssertEqual(savedUpdatedAt, installationOnServer.createdAt)
                XCTAssertNil(first.ACL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):
                XCTAssert(second.hasSameObjectId(as: installationOnServer2))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testInstallationSaveAllNoObjectIdAsync() async throws {
        let installation = Installation()
        let installation2 = Installation()

		do {
			_ = try await [installation, installation2].saveAll()
			XCTFail("Should have failed")
		} catch let error as ParseError {
			XCTAssertTrue(error.message.contains("objectId"))
		} catch {
			XCTFail("Should have thrown a ParseError")
		}
    }

    func testInstallationUpdateAll() async throws {
        var installation = Installation()
        installation.objectId = "yarr"
        installation.createdAt = Date()
        var installation2 = Installation()
        installation2.objectId = "yolo"
        installation2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

        var installationOnServer = installation
        installationOnServer.updatedAt = installationOnServer.createdAt
        installationOnServer.ACL = nil

        var installationOnServer2 = installation2
        installationOnServer2.updatedAt = installationOnServer2.createdAt
        installationOnServer2.ACL = nil

        let response = [BatchResponseItem<Installation>(success: installationOnServer, error: nil),
        BatchResponseItem<Installation>(success: installationOnServer2, error: nil)]
        let encoded: Data!
        do {
            encoded = try installationOnServer.getJSONEncoder().encode(response)
            // Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(installationOnServer)
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded1)
            let encoded2 = try ParseCoding.jsonEncoder().encode(installationOnServer2)
            installationOnServer2 = try installationOnServer.getDecoder().decode(Installation.self, from: encoded2)

        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200)
        }

        do {

            let saved = try await [installation, installation2].saveAll()

            XCTAssertEqual(saved.count, 2)
            switch saved[0] {

            case .success(let first):
                XCTAssert(first.hasSameObjectId(as: installationOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):
                XCTAssert(second.hasSameObjectId(as: installationOnServer2))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testInstallationUpdateAllNoObjectId() async throws {
        var installation = Installation()
        installation.createdAt = Date()
        var installation2 = Installation()
        installation2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        do {
            try await [installation, installation2].saveAll()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn(.missingObjectId))
        }
    }

    func testInstallationUpdateAllNoObjectIdIgnoreConfig() async throws {
        var installation = Installation()
        installation.createdAt = Date()
        var installation2 = Installation()
        installation2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

        var installationOnServer = installation
        installationOnServer.objectId = "yarr"
        installationOnServer.updatedAt = installationOnServer.createdAt
        installationOnServer.ACL = nil

        var installationOnServer2 = installation2
        installationOnServer2.objectId = "yolo"
        installationOnServer2.updatedAt = installationOnServer2.createdAt
        installationOnServer2.ACL = nil

        let response = [BatchResponseItem<Installation>(success: installationOnServer, error: nil),
        BatchResponseItem<Installation>(success: installationOnServer2, error: nil)]
        let encoded: Data!
        do {
            encoded = try installationOnServer.getJSONEncoder().encode(response)
            // Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(installationOnServer)
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded1)
            let encoded2 = try ParseCoding.jsonEncoder().encode(installationOnServer2)
            installationOnServer2 = try installationOnServer.getDecoder().decode(Installation.self, from: encoded2)

        } catch {
            XCTFail("Should have encoded/decoded. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
           return MockURLResponse(data: encoded, statusCode: 200)
        }

        do {

            let saved = try await [installation, installation2].saveAll(ignoringCustomObjectIdConfig: true)

            XCTAssertEqual(saved.count, 2)
            switch saved[0] {

            case .success(let first):
                XCTAssert(first.hasSameObjectId(as: installationOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            switch saved[1] {

            case .success(let second):
                XCTAssert(second.hasSameObjectId(as: installationOnServer2))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testInstallationUpdateAllNoObjectIdAsync() async throws {
        var installation = Installation()
        installation.createdAt = Date()
        var installation2 = Installation()
        installation2.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())

		do {
			_ = try await [installation, installation2].saveAll()
			XCTFail("Should have failed")
		} catch let error as ParseError {
			XCTAssertTrue(error.message.contains("objectId"))
		} catch {
			XCTFail("Should have thrown a ParseError")
		}
    }

    func testFetch() async throws {
        var score = GameScore(points: 10)
        let objectId = "yarr"
        score.objectId = objectId

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(scoreOnServer)
            // Get dates in correct format from ParseDecoding strategy
            scoreOnServer = try scoreOnServer.getDecoder().decode(GameScore.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        do {
            let fetched = try await score.fetch(options: [])
            XCTAssert(fetched.hasSameObjectId(as: scoreOnServer))
            guard let fetchedCreatedAt = fetched.createdAt,
                let fetchedUpdatedAt = fetched.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = scoreOnServer.createdAt,
                let originalUpdatedAt = scoreOnServer.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
            XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(fetched.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testFetchUser() async throws {
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId

        var userOnServer = user
        userOnServer.createdAt = Date()
        userOnServer.updatedAt = userOnServer.createdAt
        userOnServer.ACL = nil
        let encoded: Data!
        do {
            encoded = try userOnServer.getEncoder().encode(userOnServer, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try userOnServer.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        do {
            let fetched = try await user.fetch()
            XCTAssert(fetched.hasSameObjectId(as: userOnServer))
            guard let fetchedCreatedAt = fetched.createdAt,
                let fetchedUpdatedAt = fetched.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = userOnServer.createdAt,
                let originalUpdatedAt = userOnServer.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
            XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(fetched.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
