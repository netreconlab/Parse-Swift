import Foundation
import ParseSwift

// SERVER-SIDE: Send push notifications to channel subscribers
// WARNING: This requires the primary key and must run in a trusted server environment
// Do NOT run this in your client app - use Cloud Code or ParseServerSwift

let channelAlert = ParsePushAppleAlert(body: "Hello from ParseSwift again!")
let channelPayload = ParsePushPayloadApple(alert: channelAlert)
    .incrementBadge()

var push = ParsePush(payload: channelPayload)
push.channels = Set(["newDevices"])

// Send the push notification to all channel subscribers
Task {
    do {
        let statusId = try await push.send()
        print("The push was created with id: \"\(statusId)\"")
    } catch {
        print("Could not create push: \(error)")
    }
}
