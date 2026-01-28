import Foundation
import ParseSwift

// Check if user has opted in to notifications before sending
struct UserPreferences: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?
    
    var userId: String?
    var notificationsEnabled: Bool?
}

// Only send notifications to users who have opted in
let query = Installation.query(isNotNull(key: "objectId"))
    .where("notificationsEnabled" == true)

let alert = ParsePushAppleAlert(body: "Here's an update you subscribed to")
let payload = ParsePushPayloadApple(alert: alert)
let push = ParsePush(payload: payload, query: query)
