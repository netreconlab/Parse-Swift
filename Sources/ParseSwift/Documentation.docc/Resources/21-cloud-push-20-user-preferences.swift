import Foundation
import ParseSwift

// Only send notifications to users who have opted in
// Use a custom property on Installation to track opt-in status
let query = Installation.query(isNotNull(key: "objectId"))
    .where("customKey" == "opted-in")

let alert = ParsePushAppleAlert(body: "Here's an update you subscribed to")
let payload = ParsePushPayloadApple(alert: alert)
let push = ParsePush(payload: payload, query: query)
