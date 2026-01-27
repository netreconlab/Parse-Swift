import Foundation
import ParseSwift

// Assuming you have a saved score
let savedScore: GameScore // ... previously saved

Task {
    do {
        // Remove tags from the array
        let removeOperation = savedScore
            .operation
            .remove("tags", objects: ["action"])
        
        let updatedScore = try await removeOperation.save()
        
        print("Tags after removal: \(updatedScore.tags ?? [])")
        // All instances of "action" will be removed
    } catch {
        print("Error removing tags: \(error)")
    }
}
