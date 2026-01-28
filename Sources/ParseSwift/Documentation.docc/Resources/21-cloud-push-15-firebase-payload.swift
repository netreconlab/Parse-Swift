import Foundation
import ParseSwift

let firebaseNotification = ParsePushFirebaseNotification(body: "Hello from ParseSwift using FCM!")

// Create the Firebase payload
let firebasePayload = ParsePushPayloadFirebase(notification: firebaseNotification)
