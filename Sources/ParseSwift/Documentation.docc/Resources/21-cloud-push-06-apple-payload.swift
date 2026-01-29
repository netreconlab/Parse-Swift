import Foundation
import ParseSwift

// Create an alert with a body message
let alert = ParsePushAppleAlert(body: "Hello from ParseSwift!")

// Create the payload with the alert and set the badge count
let applePayload = ParsePushPayloadApple(alert: alert)
    .setBadge(1)
