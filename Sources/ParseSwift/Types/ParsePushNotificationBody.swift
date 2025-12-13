//
//  ParsePushNotificationBody.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/17/24.
//  Copyright © 2024 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

struct ParsePushNotificationBody: ParseTypeable {
    var `where`: QueryWhere?
    var channels: Set<String>?
    var data: AnyCodable?
    var pushTime: Date?
    var expirationTime: TimeInterval?
    var expirationInterval: Int?

    enum CodingKeys: String, CodingKey {
        case pushTime = "push_time"
        case expirationTime = "expiration_time"
        case expirationInterval = "expiration_interval"
        case `where`, channels, data
    }

    init<T: ParsePushApplePayload>(push: ParsePush<T>) {
        self.where = push.where
        self.channels = push.channels
        self.pushTime = push.pushTime
        self.expirationTime = push.expirationTime
        self.expirationInterval = push.expirationInterval
        if let payload = push.payload {
            self.data = AnyCodable(
                ParsePushAppleNotification(payload: payload)
            )
        }
    }

    init<T: ParsePushPayloadable>(push: ParsePush<T>) {
        self.where = push.where
        self.channels = push.channels
        self.pushTime = push.pushTime
        self.expirationTime = push.expirationTime
        self.expirationInterval = push.expirationInterval
        if let payload = push.payload {
            self.data = AnyCodable(
                payload
            )
        }
    }
}
