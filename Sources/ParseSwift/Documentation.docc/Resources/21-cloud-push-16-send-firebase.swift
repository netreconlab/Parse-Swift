import Foundation
import ParseSwift

// SERVER-SIDE: Send Firebase Cloud Messaging push notifications
// WARNING: This requires the primary key and must run in a trusted server environment
// Do NOT run this in your client app - use Cloud Code or ParseServerSwift

let firebaseNotification = ParsePushFirebaseNotification(body: "Hello from ParseSwift using FCM!")
let firebasePayload = ParsePushPayloadFirebase(notification: firebaseNotification)

let installationQuery = Installation.query(isNotNull(key: "objectId"))

// Create and send the Firebase push notification
let push = ParsePush(payload: firebasePayload, query: installationQuery)

Task {
    do {
        let statusId = try await push.send()
        print("The Firebase push was created with id: \"\(statusId)\"")
    } catch {
        print("Could not create push: \(error)")
    }
}
