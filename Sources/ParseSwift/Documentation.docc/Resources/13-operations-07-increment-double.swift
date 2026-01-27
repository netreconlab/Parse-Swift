import Foundation
import ParseSwift

// Assuming you have a saved score
let savedScore: GameScore // ... previously saved

Task {
    do {
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
