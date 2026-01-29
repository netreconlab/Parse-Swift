import Foundation
import ParseSwift

Task {
    do {
        // Create and save a score
        let score = GameScore(points: 100, name: "player1")
        let savedScore = try await score.save()

        // Unset (delete) the points field from the object
        let unsetOperation = savedScore
            .operation
            .unset(("points", \.points))

        let updatedScore = try await unsetOperation.save()

        print("Points field unset (removed): \(updatedScore.points == nil)")
        // The field no longer exists on the server
    } catch {
        print("Error unsetting points: \(error)")
    }
}
