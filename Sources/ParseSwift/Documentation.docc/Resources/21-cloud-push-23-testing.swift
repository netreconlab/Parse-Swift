import Foundation
import ParseSwift

// Test with a specific test installationId first (replace with a real installationId)
let testQuery = Installation.query("installationId" == "your-test-installation-id")

let testAlert = ParsePushAppleAlert(body: "Test notification")
let testPayload = ParsePushPayloadApple(alert: testAlert)
let testPush = ParsePush(payload: testPayload, query: testQuery)

Task {
    do {
        let statusId = try await testPush.send()
        print("Test push sent: \(statusId)")
        // Verify the notification displays correctly on the test device
        // Check badge count, alert text, sound, etc.
    } catch {
        print("Test failed: \(error)")
        // Fix issues before sending to production users
    }
}
