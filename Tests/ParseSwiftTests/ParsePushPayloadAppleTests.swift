//
//  ParsePushPayloadAppleTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/11/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

// swiftlint:disable line_length

class ParsePushPayloadAppleTests: XCTestCase, @unchecked Sendable {

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

    func testInitializers() throws {
        let body = "Hello from ParseSwift!"
        var applePayload = ParsePushPayloadApple(body: body)
        let appleNotification = ParsePushAppleNotification(payload: applePayload)
        XCTAssertEqual(appleNotification.description,
                       "{\"aps\":{\"alert\":{\"body\":\"\(body)\"}},\"pushType\":\"alert\"}")
        let applePayload2 = ParsePushPayloadApple(alert: .init(body: body))
        let appleNotification2 = ParsePushAppleNotification(payload: applePayload2)
        XCTAssertEqual(appleNotification, appleNotification2)
        XCTAssertEqual(applePayload.body, body)
        applePayload.alert = nil
        XCTAssertNil(applePayload.body)
        applePayload.body = body
        XCTAssertEqual(applePayload.alert, applePayload2.alert)
    }

    func testParsePushAppleNotification() throws {
        let body = "Hello from ParseSwift!"
        var applePayload = ParsePushPayloadApple(body: body)
        applePayload.collapseId = "hello"
        applePayload.pushType = .background
        applePayload.priority = 1
        let appleNotification = ParsePushAppleNotification(payload: applePayload)
        XCTAssertEqual(
            appleNotification.description,
            "{\"aps\":{\"alert\":{\"body\":\"\(body)\"}},\"collapseId\":\"hello\",\"priority\":1,\"pushType\":\"background\"}"
        )
    }

    func testBadge() throws {
        let applePayload = ParsePushPayloadApple()
            .setBadge(1)
        XCTAssertEqual(applePayload.description,
                       "{\"badge\":1}")
        let applePayload2 = ParsePushPayloadApple()
            .incrementBadge()
        XCTAssertEqual(applePayload2.description,
                       "{\"badge\":{\"__op\":\"Increment\",\"amount\":1}}")
    }

    func testSound() throws {
        let applePayload = ParsePushPayloadApple()
            .setSound("hello")
        XCTAssertEqual(applePayload.description,
                       "{\"sound\":\"hello\"}")
        let soundString: String = try applePayload.getSound()
        XCTAssertEqual(soundString, "hello")
        let sound = ParsePushAppleSound(critical: true, name: "hello", volume: 7)
        let applePayload2 = ParsePushPayloadApple()
            .setSound(sound)
        XCTAssertEqual(applePayload2.description,
                       "{\"sound\":{\"critical\":true,\"name\":\"hello\",\"volume\":7}}")
        let soundObject: ParsePushAppleSound = try applePayload2.getSound()
        XCTAssertEqual(soundObject, sound)
        XCTAssertThrowsError(try applePayload2.getSound() as String)
    }

    func testCoding() throws {
        let sound = ParsePushAppleSound(critical: true, name: "hello", volume: 7)
        var alert = ParsePushAppleAlert(body: "pull up")
        alert.titleLocKey = "yes"
        alert.title = "you"
        alert.locArgs = ["mother"]
        alert.locKey = "cousin"
        alert.action = "to"
        alert.actionLocKey = "icon"
        alert.subtitle = "trip"
        alert.subtitleLocKey = "far"
        alert.subtitleLocArgs = ["gone"]
        alert.launchImage = "it"
        alert.titleLocArgs = ["arg"]
        alert.titleLocKey = "it"
        var applePayload = ParsePushPayloadApple(alert: alert)
            .setBadge(1)
            .setSound(sound)
        applePayload.urlArgs = ["help"]
        applePayload.interruptionLevel = "yolo"
        applePayload.threadId = "yep"
        // The following are notification header fields that are lifted out of the
        // `aps` payload by `ParsePushAppleNotification`, so they do not round-trip
        // through the payload's own encoding.
        // applePayload.topic = "naw"
        // applePayload.collapseId = "nope"
        // applePayload.pushType = .background
        // applePayload.priority = 6
        applePayload.contentAvailable = 1
        applePayload.mutableContent = 1
        applePayload.targetContentId = "press"
        applePayload.relevanceScore = 2.0
        let encoded = try ParseCoding.parseEncoder().encode(applePayload)
        let decoded = try ParseCoding.jsonDecoder().decode(ParsePushPayloadApple.self, from: encoded)
        XCTAssertEqual(applePayload, decoded)
        XCTAssertEqual(applePayload.description,
                       "{\"alert\":{\"action\":\"to\",\"action-loc-key\":\"icon\",\"body\":\"pull up\",\"launch-image\":\"it\",\"loc-args\":[\"mother\"],\"loc-key\":\"cousin\",\"subtitle\":\"trip\",\"subtitle-loc-args\":[\"gone\"],\"subtitle-loc-key\":\"far\",\"title\":\"you\",\"title-loc-args\":[\"arg\"],\"title-loc-key\":\"it\"},\"badge\":1,\"content-available\":1,\"interruption-level\":\"yolo\",\"mutable-content\":1,\"relevance-score\":2,\"sound\":{\"critical\":true,\"name\":\"hello\",\"volume\":7},\"target-content-id\":\"press\",\"thread-id\":\"yep\",\"url-args\":[\"help\"]}")
        XCTAssertEqual(alert.description, "{\"action\":\"to\",\"action-loc-key\":\"icon\",\"body\":\"pull up\",\"launch-image\":\"it\",\"loc-args\":[\"mother\"],\"loc-key\":\"cousin\",\"subtitle\":\"trip\",\"subtitle-loc-args\":[\"gone\"],\"subtitle-loc-key\":\"far\",\"title\":\"you\",\"title-loc-args\":[\"arg\"],\"title-loc-key\":\"it\"}")
        let alert2 = ParsePushAppleAlert()
        XCTAssertNotEqual(alert, alert2)
        XCTAssertEqual(sound.description, "{\"critical\":true,\"name\":\"hello\",\"volume\":7}")
    }

    func testCodingAlert() throws {
        let body = "Hello from ParseSwift!"
        var applePayload = ParsePushPayloadApple(alert: .init(body: body))
        applePayload.body = "stop"
        let encoded = try ParseCoding.parseEncoder().encode(applePayload)
        let decoded = try ParseCoding.jsonDecoder().decode(ParsePushPayloadApple.self, from: encoded)
        XCTAssertEqual(applePayload, decoded)
        let anyEncodablePayload = AnyEncodable(applePayload)
        let anyEncodablePayload2 = AnyEncodable(decoded)
        XCTAssertEqual(anyEncodablePayload, anyEncodablePayload2)
        let value = "peace"
        let dictionary = [anyEncodablePayload: value]
        XCTAssertEqual(dictionary[anyEncodablePayload2], value)
    }

    func testAppleAlertStringDecode() throws {
        let sound = ParsePushAppleSound(critical: true, name: "hello", volume: 7)
        let alert = ParsePushAppleAlert(body: "pull up")
        var applePayload = ParsePushPayloadApple()
        applePayload.alert = alert
        applePayload.badge = AnyCodable(1)
        applePayload.sound = AnyCodable(sound)
        applePayload.urlArgs = ["help"]
        applePayload.interruptionLevel = "yolo"
        applePayload.threadId = "yep"
        applePayload.targetContentId = "press"
        applePayload.relevanceScore = 2.0
        applePayload.contentAvailable = 1
        applePayload.mutableContent = 1

        guard let jsonData = "{\"alert\":\"pull up\",\"badge\":1,\"content-available\":1,\"interruption-level\":\"yolo\",\"mutable-content\":1,\"relevance-score\":2,\"sound\":{\"critical\":true,\"name\":\"hello\",\"volume\":7},\"target-content-id\":\"press\",\"thread-id\":\"yep\",\"url-args\":[\"help\"]}".data(using: .utf8) else {
            XCTFail("Should have unwrapped")
            return
        }
        let decodedAlert = try ParseCoding.jsonDecoder().decode(ParsePushPayloadApple.self, from: jsonData)
        XCTAssertEqual(decodedAlert, applePayload)
    }

    func testParsePushAppleNotificationBroadcast() throws {
        guard let id = UUID(uuidString: "6b71d31d-8dfc-4e4a-8d2c-000000000001"),
              let requestId = UUID(uuidString: "6b71d31d-8dfc-4e4a-8d2c-000000000002") else {
            XCTFail("Should create UUIDs")
            return
        }
        var applePayload = ParsePushPayloadApple(body: "Hello from ParseSwift!")
        applePayload.id = id
        applePayload.requestId = requestId
        applePayload.channelId = "channel"
        applePayload.topic = "com.example.app"
        // The broadcast header fields are lifted out of the payload and set on the
        // notification so that the parse-server-push-adapter can populate the APNs headers.
        let appleNotification = ParsePushAppleNotification(payload: applePayload)
        XCTAssertEqual(appleNotification.id, id)
        XCTAssertEqual(appleNotification.requestId, requestId)
        XCTAssertEqual(appleNotification.channelId, "channel")
        XCTAssertEqual(appleNotification.topic, "com.example.app")
        XCTAssertEqual(appleNotification.pushType, .alert)
    }

    func testParsePushAppleLiveActivity() throws {
        var payload = ParsePushPayloadAppleLiveActivity()
        payload.event = .start
        payload.alert = ParsePushAppleAlert(body: "Live!")
        XCTAssertEqual(payload.pushType, .liveactivity)
        XCTAssertEqual(payload.priority, 5)
        XCTAssertEqual(payload.description,
                       "{\"alert\":{\"body\":\"Live!\"},\"event\":\"start\"}")

        let notification = ParsePushAppleNotification(payload: payload)
        XCTAssertEqual(notification.pushType, .liveactivity)
        XCTAssertEqual(notification.priority, 5)
        XCTAssertEqual(notification.description,
                       "{\"aps\":{\"alert\":{\"body\":\"Live!\"},\"event\":\"start\"},\"priority\":5,\"pushType\":\"liveactivity\"}")

        let encoded = try ParseCoding.parseEncoder().encode(payload)
        let decoded = try ParseCoding.jsonDecoder().decode(ParsePushPayloadAppleLiveActivity.self, from: encoded)
        // `priority` is a notification header default that is not encoded in the `aps`
        // payload, so only the encodable fields are compared here.
        XCTAssertEqual(decoded.event, .start)
        XCTAssertEqual(decoded.alert, payload.alert)
    }
}
