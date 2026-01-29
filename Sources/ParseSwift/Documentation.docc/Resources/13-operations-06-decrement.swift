import Foundation
import ParseSwift

Task {
    do {
        // Create and save a score
        let score = GameScore(points: 102, name: "player1")
        let savedScore = try await score.save()

        // Decrement by using a negative value
        let decrementOperation = savedScore
            .operation
            .increment("points", by: -5)

        let updatedScore = try await decrementOperation.save()

        print("Points decremented by 5")
        print("New points value: \(updatedScore.points ?? 0)")
    } catch {
        print("Error decrementing points: \(error)")
    }
}
