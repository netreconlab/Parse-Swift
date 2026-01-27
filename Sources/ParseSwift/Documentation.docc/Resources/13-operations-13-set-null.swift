import Foundation
import ParseSwift

// Assuming you have a saved score
let savedScore: GameScore // ... previously saved

Task {
    do {
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
