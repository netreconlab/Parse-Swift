import Foundation
import ParseSwift

// Create another alert for channel-based notification
let channelAlert = ParsePushAppleAlert(body: "Hello from ParseSwift again!")

// Use incrementBadge() to increase the badge count by 1
let channelPayload = ParsePushPayloadApple(alert: channelAlert)
    .incrementBadge()
