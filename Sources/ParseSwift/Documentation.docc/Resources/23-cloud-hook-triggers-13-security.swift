import Foundation
import ParseSwift

// ❌ NEVER do this in client applications
// Hook Triggers require the primary key and should only be used server-side

// ✅ Use Hook Triggers only in server-side Swift applications
// such as ParseServerSwift, Vapor, Kitura, or similar backend frameworks
Task {
    // Only run this code in a secure server environment
    // with proper authentication and access controls
    let gameScore = GameScore()
    let trigger = ParseHookTrigger(object: gameScore,
                                   trigger: .afterSave,
                                   url: URL(string: "https://api.example.com/webhook")!)
    _ = try await trigger.create()
}
