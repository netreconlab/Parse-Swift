//
//  ParsePushAppleNotification.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/16/24.
//  Copyright © 2024 Network Reconnaissance Lab. All rights reserved.
//

struct ParsePushAppleNotification<P: ParsePushApplePayload>: ParsePushPayloadable {

    var aps: P?
    var collapseId: String?
    var pushType: ParsePushPayloadApple.PushType?
    var priority: Int?
    var mdm: String?
    public init() {}

    public init(payload: P) {
        self.aps = payload
        self.collapseId = payload.collapseId
        self.pushType = payload.pushType
        self.priority = payload.priority
        self.mdm = payload.mdm
    }

    enum CodingKeys: String, CodingKey {
        case pushType = "push_type"
        case collapseId = "collapse_id"
        case mdm = "_mdm"
        case aps, priority
    }

}
