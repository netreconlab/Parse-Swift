import Foundation
import ParseSwift

// Assuming you have a saved score
let savedScore: GameScore // ... previously saved

Task {
    do {
        // Add unique tags to the array (no duplicates)
        let addUniqueOperation = savedScore
            .operation
            .addUnique("tags", objects: ["adventure", "action"])
        
        let updatedScore = try await addUniqueOperation.save()
        
        print("Unique tags added: \(updatedScore.tags ?? [])")
        // If "action" was already in the array, it won't be added again
    } catch {
        print("Error adding unique tags: \(error)")
    }
}
