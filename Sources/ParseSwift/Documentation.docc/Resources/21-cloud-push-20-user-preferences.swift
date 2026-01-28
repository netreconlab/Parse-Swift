import Foundation
import ParseSwift

// SERVER-SIDE: Only send notifications to users who have opted in
// WARNING: This requires the primary key and must run in a trusted server environment
// Do NOT run this in your client app - use Cloud Code or ParseServerSwift/Vapor

// Use a custom property on Installation to track opt-in status
let query = Installation.query(isNotNull(key: "objectId"))
    .where("customKey" == "opted-in")

let alert = ParsePushAppleAlert(body: "Here's an update you subscribed to")
let payload = ParsePushPayloadApple(alert: alert)
let push = ParsePush(payload: payload, query: query)

Task {
    do {
        try await push.send()
        print("Successfully sent push notification to opted-in users.")
    } catch {
        print("Error sending push notification to opted-in users: \(error)")
    }
}
