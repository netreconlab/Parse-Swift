import Foundation
import ParseSwift

// Assuming you have a saved score
let savedScore: GameScore // ... previously saved

Task {
    do {
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
