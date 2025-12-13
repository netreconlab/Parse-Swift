//
//  ParsePushAppleNotification.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/16/24.
//  Copyright © 2024 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

struct ParsePushAppleNotification<P: ParsePushApplePayload>: ParsePushAppleHeader, ParsePushPayloadable {

    struct APS: ParseTypeable {
        var payload: P

        enum CodingKeys: String, CodingKey {
            case payload = "aps"
        }
    }

    // Notification Header properties set by parse-server-push-adapter.
    var collapseId: String?
    var priority: Int?
    var pushType: ParsePushPayloadApple.PushType?
    var topic: String?

    // Notification Header properties set directly.
    var id: UUID?
    var requestId: UUID?
    var channelId: String?
    var payload: APS?

    public init() {}

    init(
        id: UUID? = nil,
        collapseId: String? = nil,
        requestId: UUID? = nil,
        channelId: String? = nil,
        priority: Int? = nil,
        topic: String? = nil,
        payload: P
    ) {
        self.id = id
        self.collapseId = collapseId
        self.requestId = requestId
        self.channelId = channelId
        self.priority = priority
        self.topic = topic
        self.pushType = payload.pushType
        self.payload = APS(payload: payload)
    }

    enum CodingKeys: String, CodingKey {
        case pushType = "push_type"
        case payload = "rawPayload"
        case collapseId, priority, topic, id, requestId, channelId
    }

}

extension ParsePushAppleNotification where P: ParsePushApplePayload & ParsePushAppleHeader {

    init(
        id: UUID? = nil,
        payload: P
    ) {
        self.id = id
        self.collapseId = payload.collapseId
        self.pushType = payload.pushType
        self.priority = payload.priority
        self.topic = payload.topic
        self.payload = APS(payload: payload)
    }
}
