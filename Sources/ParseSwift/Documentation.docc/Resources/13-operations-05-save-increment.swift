import Foundation
import ParseSwift

Task {
    do {
        // Create and save a score
        let score = GameScore(points: 102, name: "player1")
        let savedScore = try await score.save()
        
        // Create an increment operation
        let incrementOperation = savedScore
            .operation
            .increment("points", by: 1)
        
        // Save the increment operation to apply it on the server
        let updatedScore = try await incrementOperation.save()
        
        print("Points incremented successfully")
        print("New points value: \(updatedScore.points ?? 0)")
    } catch {
        print("Error incrementing points: \(error)")
    }
}
