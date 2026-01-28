import Foundation
import ParseSwift

// Only send notifications to users who have opted in
// The Installation model should have a notificationsEnabled property
let query = Installation.query(isNotNull(key: "objectId"))
    .where("notificationsEnabled" == true)

let alert = ParsePushAppleAlert(body: "Here's an update you subscribed to")
let payload = ParsePushPayloadApple(alert: alert)
let push = ParsePush(payload: payload, query: query)
