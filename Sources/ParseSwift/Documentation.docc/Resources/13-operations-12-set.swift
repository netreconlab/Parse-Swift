import Foundation
import ParseSwift

Task {
    do {
        // Create and save a score
        let score = GameScore(points: 100, name: "player1")
        let savedScore = try await score.save()

        // Set the name field (only updates if value changed)
        let setOperation = savedScore
            .operation
            .set(("name", \.name), to: "player2")

        let updatedScore = try await setOperation.save()

        print("Name updated: \(updatedScore.name ?? "nil")")
    } catch {
        print("Error setting name: \(error)")
    }
}
