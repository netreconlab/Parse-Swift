import Foundation
import ParseSwift

// Define triggers during server deployment or initialization
func setupDatabaseTriggers() async throws {
    // Create triggers for important database events
    let gameScore = GameScore()
    
    let afterSaveTrigger = ParseHookTrigger(
        object: gameScore,
        trigger: .afterSave,
        url: URL(string: "https://webhooks.myapp.com/gameScore/afterSave")!
    )
    
    let beforeDeleteTrigger = ParseHookTrigger(
        object: gameScore,
        trigger: .beforeDelete,
        url: URL(string: "https://webhooks.myapp.com/gameScore/beforeDelete")!
    )
    
    // Create or update triggers
    _ = try await afterSaveTrigger.create()
    _ = try await beforeDeleteTrigger.create()
    
    print("Database triggers configured successfully")
}
