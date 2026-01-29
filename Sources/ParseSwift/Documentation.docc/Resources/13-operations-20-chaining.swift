import Foundation
import ParseSwift

Task {
    do {
        // Create and save a score
        let score = GameScore(points: 100, name: "player1", tags: ["beginner"])
        let savedScore = try await score.save()

        // Chain multiple operations together
        let combinedOperation = savedScore
            .operation
            .increment("points", by: 10)
            .add("tags", objects: ["featured"])
            .set(("name", \.name), to: "champion")

        print("Created combined operation with increment, add, and set")

        // Save all combined operations atomically
        let updatedScore = try await combinedOperation.save()

        print("All operations applied successfully")
        print("Points: \(updatedScore.points ?? 0)")
        print("Tags: \(updatedScore.tags ?? [])")
        print("Name: \(updatedScore.name ?? "nil")")
    } catch {
        print("Error saving combined operations: \(error)")
    }
}
