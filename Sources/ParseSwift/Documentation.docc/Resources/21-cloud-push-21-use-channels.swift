import Foundation
import ParseSwift

// CLIENT-SIDE: Let users subscribe to topics they care about
// This runs in your client app without requiring the primary key
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

// SERVER-SIDE: Send targeted notifications to specific topics
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
