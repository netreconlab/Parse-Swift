import Foundation
import ParseSwift

// Create a GameScore with initial values
let score = GameScore(points: 102, name: "player1")

Task {
    do {
        // Save the score to get an objectId
        let savedScore = try await score.save()

        print("Saved score: \(savedScore)")
        print("Initial points: \(savedScore.points ?? 0)")
    } catch {
        print("Error saving score: \(error)")
    }
}
