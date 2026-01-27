import Foundation
import ParseSwift

Task {
    do {
        // Create and save a score
        let score = GameScore(points: 100, name: "player1")
        let savedScore = try await score.save()
        
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
