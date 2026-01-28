import Foundation
import ParseSwift

// Let users subscribe to topics they care about
var installation = Installation.current()
installation.channels = ["sports", "news", "weather"]

Task {
    do {
        try await installation.save()
        print("Subscribed to channels")
    } catch {
        print("Error subscribing: \(error)")
    }
}

// Send targeted notifications to specific topics
let alert = ParsePushAppleAlert(body: "Breaking sports news!")
let payload = ParsePushPayloadApple(alert: alert)

var push = ParsePush(payload: payload)
push.channels = Set(["sports"])
