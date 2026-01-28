import Foundation
import ParseSwift

// Use migrations to manage trigger changes across environments
func migrateTriggers() async throws {
    let gameScore = GameScore()

    // Fetch all existing triggers
    let existingTriggers = try await ParseHookTrigger.fetchAll()

    // Check if our trigger already exists
    let triggerExists = existingTriggers.contains { trigger in
        trigger.className == gameScore.className &&
        trigger.trigger == .afterSave
    }

    if !triggerExists {
        // Create the trigger if it doesn't exist
        let newTrigger = ParseHookTrigger(
            object: gameScore,
            trigger: .afterSave,
            url: URL(string: "https://api.example.com/webhook")!
        )
        _ = try await newTrigger.create()
        print("Created afterSave trigger for GameScore")
    } else {
        print("Trigger already exists, skipping creation")
    }
}
