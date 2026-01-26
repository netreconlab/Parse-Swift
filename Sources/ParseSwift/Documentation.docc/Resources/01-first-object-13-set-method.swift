import Foundation
import ParseSwift

Task {
    do {
        let score = GameScore(points: 10)
        let savedScore = try await score.save()
        
        // Instead of using `.mergeable`, you can use the `set()` method
        // which allows you to accomplish the same thing
        var changedScore = savedScore.set(\.points, to: 200)
        
        let updatedScore = try await changedScore.save()
        
        assert(updatedScore.points == 200)
        assert(savedScore.objectId == updatedScore.objectId)
        
        print("Updated score: \(updatedScore)")
    } catch {
        print("Error updating: \(error)")
    }
}
