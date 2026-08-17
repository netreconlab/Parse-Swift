import Foundation
import ParseSwift

// Define initial GameScore with custom objectId
let score = GameScore(objectId: "myObjectId", points: 10)

Task {
    do {
        // Save the score with custom objectId
        let savedScore = try await score.save()

        // Verify the custom objectId was preserved
        assert(savedScore.objectId == "myObjectId")
        assert(savedScore.createdAt != nil)
        assert(savedScore.updatedAt != nil)
        assert(savedScore.points == 10)

        print("Successfully saved with custom objectId: \(savedScore.objectId ?? "nil")")
    } catch {
        print("Error saving: \(error)")
    }
}
