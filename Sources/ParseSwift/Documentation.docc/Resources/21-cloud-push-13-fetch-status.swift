import Foundation
import ParseSwift

let alert = ParsePushAppleAlert(body: "Hello from ParseSwift!")
let applePayload = ParsePushPayloadApple(alert: alert)
    .setBadge(1)

let installationQuery = Installation.query(isNotNull(key: "objectId"))
let push = ParsePush(payload: applePayload, query: installationQuery)

// Fetch the status of the notification after successfully sending the push
Task {
    do {
        let statusId = try await push.send()
        let pushStatus = try await push.fetchStatus(statusId)
        print("The push status is: \"\(pushStatus)\"")
    } catch {
        print("Could not send push or fetch status: \(error)")
    }
}
