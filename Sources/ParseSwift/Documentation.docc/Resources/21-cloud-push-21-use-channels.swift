import Foundation
import ParseSwift

// Let users subscribe to topics they care about
Task {
    do {
        var installation = try await Installation.current()
        installation.channels = ["sports", "news", "weather"]
        try await installation.save()
        print("Subscribed to channels")
    } catch {
        print("Error subscribing: \(error)")
    }
}

// Send targeted notifications to specific topics
// WARNING: This requires the primary key and must run in a trusted server environment
// Do NOT run this in your client app - use Cloud Code or Parse-Server-Swift/Vapor
let alert = ParsePushAppleAlert(body: "Breaking sports news!")
let payload = ParsePushPayloadApple(alert: alert)

var push = ParsePush(payload: payload)
push.channels = Set(["sports"])

Task {
    do {
        try await push.send()
        print("Push sent to sports channel")
    } catch {
        print("Error sending push: \(error)")
    }
}
