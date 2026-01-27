import Foundation
import ParseSwift

// Assuming you have a saved score
let savedScore: GameScore // ... previously saved

Task {
    do {
        // Force set the name field (always updates even if unchanged)
        let forceSetOperation = savedScore
            .operation
            .forceSet(("name", \.name), to: "player3")
        
        let updatedScore = try await forceSetOperation.save()
        
        print("Name force set: \(updatedScore.name ?? "nil")")
    } catch {
        print("Error force setting name: \(error)")
    }
}
