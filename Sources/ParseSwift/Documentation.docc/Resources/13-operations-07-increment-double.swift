import Foundation
import ParseSwift

Task {
    do {
        // Create and save a score
        let score = GameScore(points: 102, name: "player1")
        let savedScore = try await score.save()
        
        // Increment by a decimal amount
        let incrementDoubleOperation = savedScore
            .operation
            .increment("points", by: 2.5)
        
        let updatedScore = try await incrementDoubleOperation.save()
        
        print("Points incremented by 2.5")
        print("New points value: \(updatedScore.points ?? 0)")
    } catch {
        print("Error incrementing points: \(error)")
    }
}
