import Foundation
import ParseSwift

Task {
    do {
        // Create and save a score with tags
        let score = GameScore(points: 100, name: "player1", tags: ["action", "adventure"])
        let savedScore = try await score.save()
        
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
