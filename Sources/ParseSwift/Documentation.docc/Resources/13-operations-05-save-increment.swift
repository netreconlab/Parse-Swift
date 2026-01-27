import Foundation
import ParseSwift

// Assuming you have an increment operation from the previous step
let incrementOperation: ParseOperation<GameScore> // ... from previous step

Task {
    do {
        // Save the increment operation to apply it on the server
        let updatedScore = try await incrementOperation.save()
        
        print("Points incremented successfully")
        print("New points value: \(updatedScore.points ?? 0)")
    } catch {
        print("Error incrementing points: \(error)")
    }
}
