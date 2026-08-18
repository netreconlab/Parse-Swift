//
//  ParsePushPayloadAppleLiveActivity.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/16/24.
//  Copyright © 2024 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

/// The payload data for an Apple LiveActivity push notification.
/// For more information, see [Apple's documentation](https://developer.apple.com/documentation/activitykit/starting-and-updating-live-activities-with-activitykit-push-notifications).
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

    /// The string that describes whether you start, update, or end an ongoing Live Activity.
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

    public var id: UUID?

    public var requestId: UUID?

    public var channelId: String?

    public var alert: ParsePushAppleAlert?

    /**
     The UNIX timestamp that marks the time when you send the remote notification that updates
     or ends a Live Activity. It is recommended to always set this to the current time in seconds
     since 1970 so the system can display the most recent update.
     */
    public var timestamp: Int?

    /**
     The UNIX timestamp that represents the date at which a Live Activity becomes stale, or out of date.
     */
    public var staleDate: Int?

    /**
     The UNIX timestamp that represents the date at which the system ends a Live Activity and removes
     it from the Dynamic Island and the Lock Screen.
     */
    public var dismissalDate: Int?

    /**
     A string you use when you start a Live Activity with a remote push notification. It must match the
     name of the structure that describes the dynamic data that appears in a Live Activity.
     */
    public var attributesType: String?

    /**
     The criteria the system evaluates to determine if it displays the notification in the current Focus.
     */
    public var filterCriteria: String?

    var badge: AnyCodable?
    var sound: AnyCodable?
    var contentState: AnyCodable?
    var attributes: AnyCodable?

    enum CodingKeys: String, CodingKey {
        case relevanceScore = "relevance-score"
        case targetContentId = "target-content-id"
        case mutableContent = "mutable-content"
        case contentAvailable = "content-available"
        case interruptionLevel = "interruption-level"
        case urlArgs = "url-args"
        case threadId = "thread-id"
        case contentState = "content-state"
        case staleDate = "stale-date"
        case dismissalDate = "dismissal-date"
        case attributesType = "attributes-type"
        case filterCriteria = "filter-criteria"
        case category, sound, badge, alert, event, timestamp, attributes
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
        event = try values.decodeIfPresent(Event.self, forKey: .event)
        timestamp = try values.decodeIfPresent(Int.self, forKey: .timestamp)
        staleDate = try values.decodeIfPresent(Int.self, forKey: .staleDate)
        dismissalDate = try values.decodeIfPresent(Int.self, forKey: .dismissalDate)
        attributesType = try values.decodeIfPresent(String.self, forKey: .attributesType)
        contentState = try values.decodeIfPresent(AnyCodable.self, forKey: .contentState)
        attributes = try values.decodeIfPresent(AnyCodable.self, forKey: .attributes)
        filterCriteria = try values.decodeIfPresent(String.self, forKey: .filterCriteria)
        interruptionLevel = try values.decodeIfPresent(String.self, forKey: .interruptionLevel)
        urlArgs = try values.decodeIfPresent([String].self, forKey: .urlArgs)
    }
}

extension ParsePushPayloadAppleLiveActivity {

    /**
     Set the updated or final content for a Live Activity. The content must match the data you
     describe with your custom [ActivityAttributes](https://developer.apple.com/documentation/activitykit/activityattributes)
     `ContentState` implementation.
     - parameter contentState: Any `Codable` object that matches your `ContentState`.
     - returns: A mutated instance of `ParsePushPayloadAppleLiveActivity` for easy chaining.
     */
    public func setContentState<V>(_ contentState: V) -> Self where V: Codable & Sendable {
        var mutablePayload = self
        mutablePayload.contentState = AnyCodable(contentState)
        return mutablePayload
    }

    /**
     Get the `content-state` using any type that conforms to `Codable`.
     - returns: The content state casted to the inferred type.
     - throws: An error of type `ParseError`.
     */
    public func getContentState<V>() throws -> V where V: Codable & Sendable {
        guard let contentState = contentState?.value as? V else {
            throw ParseError(code: .otherCause,
                             message: "Cannot be casted to the inferred type")
        }
        return contentState
    }

    /**
     Set the data to pass to a Live Activity that you start with a remote push notification.
     - parameter attributes: Any `Codable` object that matches your `ActivityAttributes`.
     - returns: A mutated instance of `ParsePushPayloadAppleLiveActivity` for easy chaining.
     - warning: Used along with `attributesType` when the `event` is `start`.
     */
    public func setAttributes<V>(_ attributes: V) -> Self where V: Codable & Sendable {
        var mutablePayload = self
        mutablePayload.attributes = AnyCodable(attributes)
        return mutablePayload
    }

    /**
     Get the `attributes` using any type that conforms to `Codable`.
     - returns: The attributes casted to the inferred type.
     - throws: An error of type `ParseError`.
     */
    public func getAttributes<V>() throws -> V where V: Codable & Sendable {
        guard let attributes = attributes?.value as? V else {
            throw ParseError(code: .otherCause,
                             message: "Cannot be casted to the inferred type")
        }
        return attributes
    }
}
