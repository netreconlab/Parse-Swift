import Foundation
import ParseSwift

Task {
    do {
        // Create and save a score with tags
        let score = GameScore(points: 100, name: "player1", tags: ["action"])
        let savedScore = try await score.save()
        
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
