//
//  ParsePushApplePayload.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/16/24.
//  Copyright © 2024 Network Reconnaissance Lab. All rights reserved.
//

// swiftlint:disable line_length

protocol ParsePushApplePayload: ParsePushApplePayloadable {
    /**
     The background notification flag. If you are a writing an app using the Remote Notification
     Background Mode introduced in iOS7 (a.k.a. “Background Push”), set this value to
     1 to trigger a background update. For more informaiton, see [Apple's documentation](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/pushing_background_updates_to_your_app).
     - warning: For Apple OS's only. You also have to set `pushType` starting iOS 13
     and watchOS 6.
     */
    var contentAvailable: Int? { get set }
    /**
     The notification service app extension flag. Set this value to 1 to trigger the system to pass the notification to your notification service app extension before delivery. Use your extension to modify the notification’s content. For more informaiton, see [Apple's documentation](https://developer.apple.com/documentation/usernotifications/modifying_content_in_newly_delivered_notifications).
     - warning: You also have to set `pushType` starting iOS 13
     and watchOS 6.
     */
    var mutableContent: Int? { get set }
    /**
     The priority of the notification. Specify 10 to send the notification immediately.
     Specify 5 to send the notification based on power considerations on the user’s device.
     See Apple's [documentation](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/sending_notification_requests_to_apns)
     for more information.
     - warning: For Apple OS's only.
     */
    var priority: Int? { get set }

    var pushType: ParsePushPayloadApple.PushType? { get set }

    var badge: AnyCodable? { get set }
    var sound: AnyCodable? { get set }
}

extension ParsePushApplePayload {

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
    public func setSound<V>(_ sound: V) -> Self where V: Codable {
        var mutablePayload = self
        mutablePayload.sound = AnyCodable(sound)
        return mutablePayload
    }

    /**
     Get the sound using any type that conforms to `Codable`.
     - returns: The sound casted to the inferred type.
     - throws: An error of type `ParseError`.
     */
    public func getSound<V>() throws -> V where V: Codable {
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
