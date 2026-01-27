import Foundation
import ParseSwift

// Assuming you have a saved score
let savedScore: GameScore // ... previously saved

Task {
    do {
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
