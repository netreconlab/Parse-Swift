import Foundation
import ParseSwift

// SERVER-SIDE: Send push notifications from server
// WARNING: This requires the primary key and must run in a trusted server environment
// Do NOT run this in your client app - use Cloud Code or ParseServerSwift

let alert = ParsePushAppleAlert(body: "Hello from ParseSwift!")
let applePayload = ParsePushPayloadApple(alert: alert)
    .setBadge(1)

let installationQuery = Installation.query(isNotNull(key: "objectId"))
let push = ParsePush(payload: applePayload, query: installationQuery)

// Send the push notification using async/await
Task {
    do {
        let statusId = try await push.send()
        print("The push was created with id: \"\(statusId)\"")
    } catch {
        print("Could not create push: \(error)")
    }
}
