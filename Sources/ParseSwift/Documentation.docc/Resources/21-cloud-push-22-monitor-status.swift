import Foundation
import ParseSwift

// SERVER-SIDE: Monitor push notification delivery status
// WARNING: This requires the primary key and must run in a trusted server environment
// Do NOT run this in your client app - use Cloud Code or Parse-Server-Swift/Vapor

let alert = ParsePushAppleAlert(body: "Important update")
let payload = ParsePushPayloadApple(alert: alert)
let query = Installation.query(isNotNull(key: "objectId"))
let push = ParsePush(payload: payload, query: query)

// Track the status of your push notifications
Task {
    do {
        let statusId = try await push.send()
        // Monitor delivery status
        let status = try await push.fetchStatus(statusId)

        // Log status for monitoring
        print("Push sent to \(status.numSent ?? 0) devices")
        if let failed = status.numFailed, failed > 0 {
            print("Warning: \(failed) failed deliveries")
        }
    } catch {
        print("Push monitoring failed: \(error)")
    }
}
