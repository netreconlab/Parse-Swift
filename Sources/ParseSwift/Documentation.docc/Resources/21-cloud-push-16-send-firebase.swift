import Foundation
import ParseSwift

let firebaseNotification = ParsePushFirebaseNotification(body: "Hello from ParseSwift using FCM!")
let firebasePayload = ParsePushPayloadFirebase(notification: firebaseNotification)

let installationQuery = Installation.query(isNotNull(key: "objectId"))

// Create and send the Firebase push notification
let push = ParsePush(payload: firebasePayload, query: installationQuery)

push.send { result in
    switch result {
    case .success(let statusId):
        print("The Firebase push was created with id: \"\(statusId)\"")
    case .failure(let error):
        print("Could not create push: \(error)")
    }
}
