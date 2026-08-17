import Foundation
import ParseSwift

Task {
    do {
        let score = GameScore(objectId: "myObjectId", points: 10)
        let savedScore = try await score.save()

        // Create a mutable copy using .mergeable
        var changedScore = savedScore.mergeable
        changedScore.points = 200

        // Save the updated score
        let updatedScore = try await changedScore.save()

        // Verify the update succeeded and objectId remained the same
        assert(updatedScore.points == 200)
        assert(savedScore.objectId == updatedScore.objectId)

        print("Updated score: \(updatedScore)")
        print("ObjectId unchanged: \(updatedScore.objectId ?? "nil")")
    } catch {
        print("Error updating: \(error)")
    }
}
