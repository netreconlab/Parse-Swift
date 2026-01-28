import Foundation
import ParseSwift

// Test with a specific test device first
let testQuery = Installation.query("installationId" == "your-test-device-id")

let testAlert = ParsePushAppleAlert(body: "Test notification")
let testPayload = ParsePushPayloadApple(alert: testAlert)
let testPush = ParsePush(payload: testPayload, query: testQuery)

testPush.send { result in
    switch result {
    case .success(let statusId):
        print("Test push sent: \(statusId)")
        // Verify the notification displays correctly on the test device
        // Check badge count, alert text, sound, etc.
    case .failure(let error):
        print("Test failed: \(error)")
        // Fix issues before sending to production users
    }
}
