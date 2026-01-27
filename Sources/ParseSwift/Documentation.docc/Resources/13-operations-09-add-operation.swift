import Foundation
import ParseSwift

// Assuming you have a saved score
let savedScore: GameScore // ... previously saved

Task {
    do {
        // Add tags to the array (allows duplicates)
        let addOperation = savedScore
            .operation
            .add("tags", objects: ["action", "multiplayer"])
        
        let updatedScore = try await addOperation.save()
        
        print("Tags added: \(updatedScore.tags ?? [])")
    } catch {
        print("Error adding tags: \(error)")
    }
}
