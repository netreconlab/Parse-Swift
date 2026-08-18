//
//  ParsePushAppleNotification.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/16/24.
//  Copyright © 2024 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

struct ParsePushAppleNotification<P: ParsePushApplePayload>: ParsePushAppleHeader, ParsePushPayloadable {

    // Notification Header properties set by parse-server-push-adapter.
    var collapseId: String?
    var priority: Int?
    var pushType: ParsePushPayloadApple.PushType?
    var topic: String?

    // Notification Header properties used for broadcast push notifications.
    var id: UUID?
    var requestId: UUID?
    var channelId: String?

    // The `aps` payload delivered to the device.
    var payload: P?

    public init() {}

    init(payload: P) {
        self.id = payload.id
        self.collapseId = payload.collapseId
        self.requestId = payload.requestId
        self.channelId = payload.channelId
        self.priority = payload.priority
        self.topic = payload.topic
        self.pushType = payload.pushType
        self.payload = payload
    }

    enum CodingKeys: String, CodingKey {
        case payload = "aps"
        case collapseId, priority, topic, id, requestId, channelId, pushType
    }

}
