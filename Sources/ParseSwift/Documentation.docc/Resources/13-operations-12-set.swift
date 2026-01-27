import Foundation
import ParseSwift

// Assuming you have a saved score
let savedScore: GameScore // ... previously saved

Task {
    do {
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
