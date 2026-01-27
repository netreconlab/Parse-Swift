import Foundation
import ParseSwift

// Assuming you have a combined operation from the previous step
let combinedOperation: ParseOperation<GameScore> // ... from previous step

Task {
    do {
        // Save all combined operations atomically
        let updatedScore = try await combinedOperation.save()
        
        print("All operations applied successfully")
        print("Points: \(updatedScore.points ?? 0)")
        print("Tags: \(updatedScore.tags ?? [])")
        print("Name: \(updatedScore.name ?? "nil")")
        // All changes are applied atomically on the server
    } catch {
        print("Error saving combined operations: \(error)")
    }
}
