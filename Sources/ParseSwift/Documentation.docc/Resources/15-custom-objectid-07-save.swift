import Foundation
import ParseSwift

// Define initial GameScore with custom objectId
let score = GameScore(objectId: "myObjectId", points: 10)

Task {
    do {
        // Save the score with custom objectId
        let savedScore = try await score.save()
        
        print("Saved score: \(savedScore)")
        print("ObjectId: \(savedScore.objectId ?? "nil")")
        print("Points: \(savedScore.points ?? 0)")
    } catch {
        print("Error saving: \(error)")
    }
}
