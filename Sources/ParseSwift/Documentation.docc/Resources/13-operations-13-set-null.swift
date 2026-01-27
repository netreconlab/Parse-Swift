import Foundation
import ParseSwift

Task {
    do {
        // Create and save a score
        let score = GameScore(points: 100, name: "player1")
        let savedScore = try await score.save()

        // Set the name field to null
        let setToNullOperation = savedScore
            .operation
            .set(("name", \.name), to: nil)

        let updatedScore = try await setToNullOperation.save()

        print("Name set to null: \(updatedScore.name == nil)")
        // The field exists but has a null value
    } catch {
        print("Error setting name to null: \(error)")
    }
}
