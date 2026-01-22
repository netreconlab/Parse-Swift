//
//  ParsePushPayload.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/5/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

/// The payload data for an Apple push notification.
public struct ParsePushPayloadApple: ParsePushApplePayload {

    // MARK: Header and other high level information.
    public var collapseId: String?
    public var mdm: String?
    public var priority: Int?
    public var pushType: PushType? = .alert
    public var topic: String?

    // MARK: APS information.
    public var contentAvailable: Int?
    public var mutableContent: Int?
    public var relevanceScore: Double?
    public var targetContentId: String?
    public var interruptionLevel: String?
    public var category: String?
    public var urlArgs: [String]?
    public var threadId: String?
    public var alert: ParsePushAppleAlert?

    var badge: AnyCodable?
    var sound: AnyCodable?

    /// The type of notification.
    /// For more details, see [Apple Documentation](https://developer.apple.com/documentation/usernotifications/sending-notification-requests-to-apns).
    public enum PushType: String, Codable, Sendable {
        /// Send as an alert.
        case alert
        /// Send as a background notification.
        case background
        /// Send as a Push to Talk notification.
        case location
        case voip
        case complication
        case fileprovider
        case mdm
        case pushtotalk
        /// Send as a Live Activity notification.
        case liveactivity

        func appendRequiredInformationToTopic(
            _ topic: String
        ) -> String {
            switch self {
            case .location:
                return "\(topic).location-query"
            case .voip:
                return "\(topic).voip"
            case .complication:
                return "\(topic).complication"
            case .fileprovider:
                return "\(topic).pushkit.fileprovider"
            case .liveactivity:
                return "\(topic).push-type.liveactivity"
            case .pushtotalk:
                return "\(topic).voip-ptt"
            default:
                return topic
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case relevanceScore = "relevance-score"
        case targetContentId = "target-content-id"
        case mutableContent = "mutable-content"
        case contentAvailable = "content-available"
        case interruptionLevel = "interruption-level"
        case urlArgs = "url-args"
        case threadId = "thread-id"
        case category, sound, badge, alert
    }

    public init() {}

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
        interruptionLevel = try values.decodeIfPresent(String.self, forKey: .interruptionLevel)
        urlArgs = try values.decodeIfPresent([String].self, forKey: .urlArgs)
    }
}

extension ParsePushPayloadApple {

    /**
     Set the name of a sound file in your app’s main bundle or in the Library/Sounds folder
     of your app’s container directory. For information about how to prepare sounds, see
     [UNNotificationSound](https://developer.apple.com/documentation/usernotifications/unnotificationsound).
     - parameter sound: An instance of `ParsePushAppleSound`.
     - returns: A mutated instance of `ParsePushPayloadApple` for easy chaining.
     - warning: For Apple OS's only.
     */
    public func setSound(_ sound: ParsePushAppleSound) -> Self {
        var mutablePayload = self
        mutablePayload.sound = AnyCodable(sound)
        return mutablePayload
    }

    /**
     Set the name of a sound file in your app’s main bundle or in the Library/Sounds folder
     of your app’s container directory. Specify the string “default” to play the system
     sound. Pass a string for **regular** notifications. For critical alerts, pass the sound
     `ParsePushAppleSound` instead. For information about how to prepare sounds, see
     [UNNotificationSound](https://developer.apple.com/documentation/usernotifications/unnotificationsound).
     - parameter sound: A `String` or any `Codable` object that can be sent to APN.
     - returns: A mutated instance of `ParsePushPayloadApple` for easy chaining.
     - warning: For Apple OS's only.
     */
    public func setSound<V>(_ sound: V) -> Self where V: Codable & Sendable {
        var mutablePayload = self
        mutablePayload.sound = AnyCodable(sound)
        return mutablePayload
    }

    /**
     Get the sound using any type that conforms to `Codable`.
     - returns: The sound casted to the inferred type.
     - throws: An error of type `ParseError`.
     */
    public func getSound<V>() throws -> V where V: Codable & Sendable {
        guard let sound = sound?.value as? V else {
            throw ParseError(code: .otherCause,
                             message: "Cannot be casted to the inferred type")
        }
        return sound
    }

    /**
     Set the badge to a specific value to display on your app's icon.
     - parameter badge: The number to display in a badge on your app’s icon.
     Specify 0 to remove the current badge, if any.
     - returns: A mutated instance of `ParsePushPayloadApple` for easy chaining.
     - warning: For Apple OS's only.
     */
    public func setBadge(_ number: Int) -> Self {
        var mutablePayload = self
        mutablePayload.badge = AnyCodable(number)
        return mutablePayload
    }

    /**
     Increment the badge value by 1 to display on your app's icon.
     - warning: For Apple OS's only.
     - returns: A mutated instance of `ParsePushPayloadApple` for easy chaining.
     */
    public func incrementBadge() -> Self {
        var mutablePayload = self
        mutablePayload.badge = AnyCodable(ParseOperationIncrement(amount: 1))
        return mutablePayload
    }
}
