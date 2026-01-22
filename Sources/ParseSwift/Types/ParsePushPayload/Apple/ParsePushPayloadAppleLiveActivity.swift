//
//  ParsePushPayloadAppleLiveActivity.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/16/24.
//  Copyright © 2024 Network Reconnaissance Lab. All rights reserved.
//

/// The payload data for an Apple LiveActivity push notification.
public struct ParsePushPayloadAppleLiveActivity: ParsePushApplePayload {

    /// A LiveActivity event.
    public enum Event: String, Sendable, Codable {
        /// Start a LiveActivity.
        case start
        /// Update a LiveActivity.
        case update
        /// End a LiveActivity.
        case end
    }

    public var event: Event?

    public var contentAvailable: Int?

    public var mutableContent: Int?

    public var priority: Int?

    public var topic: String?

    public var collapseId: String?

    public var relevanceScore: Double?

    public var targetContentId: String?

    public var interruptionLevel: String?

    public var pushType: ParsePushPayloadApple.PushType? = .liveactivity

    public var category: String?

    public var urlArgs: [String]?

    public var threadId: String?

    public var mdm: String?

    public var alert: ParsePushAppleAlert?

    var badge: AnyCodable?
    var sound: AnyCodable?

    enum CodingKeys: String, CodingKey {
        case relevanceScore = "relevance-score"
        case targetContentId = "target-content-id"
        case mutableContent = "mutable-content"
        case contentAvailable = "content-available"
        case interruptionLevel = "interruption-level"
        case urlArgs = "url-args"
        case threadId = "thread-id"
        case category, sound, badge, alert, topic
    }

    public init() {
        // Set to the lowest live activity priority by default.
        priority = 5
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        do {
            alert = try values.decode(ParsePushAppleAlert.self, forKey: .alert)
        } catch {
            if let alertBody = try values.decodeIfPresent(String.self, forKey: .alert) {
                alert = ParsePushAppleAlert(body: alertBody)
            }
        }
        relevanceScore = try values.decodeIfPresent(Double.self, forKey: .relevanceScore)
        targetContentId = try values.decodeIfPresent(String.self, forKey: .targetContentId)
        mutableContent = try values.decodeIfPresent(Int.self, forKey: .mutableContent)
        contentAvailable = try values.decodeIfPresent(Int.self, forKey: .contentAvailable)
        category = try values.decodeIfPresent(String.self, forKey: .category)
        sound = try values.decodeIfPresent(AnyCodable.self, forKey: .sound)
        badge = try values.decodeIfPresent(AnyCodable.self, forKey: .badge)
        threadId = try values.decodeIfPresent(String.self, forKey: .threadId)
        topic = try values.decodeIfPresent(String.self, forKey: .topic)
        interruptionLevel = try values.decodeIfPresent(String.self, forKey: .interruptionLevel)
        urlArgs = try values.decodeIfPresent([String].self, forKey: .urlArgs)
    }
}
