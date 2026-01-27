import Foundation
import ParseSwift

Task {
    do {
        // Create and save a score with tags
        let score = GameScore(points: 100, name: "player1", tags: ["action"])
        let savedScore = try await score.save()
        
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
