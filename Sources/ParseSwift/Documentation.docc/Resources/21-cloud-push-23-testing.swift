import Foundation
import ParseSwift

// SERVER-SIDE: Test with a specific installation before production deployment
// WARNING: This requires the primary key and must run in a trusted server environment
// Do NOT run this in your client app - use Cloud Code or ParseServerSwift/Vapor

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
