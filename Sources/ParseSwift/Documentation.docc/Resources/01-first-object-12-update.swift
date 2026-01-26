import Foundation
import ParseSwift

Task {
    do {
        let score = GameScore(points: 10)
        let savedScore = try await score.save()
        
        var changedScore = savedScore.mergeable
        changedScore.points = 200
        
        let updatedScore = try await changedScore.save()
        
        assert(updatedScore.points == 200)
        assert(savedScore.objectId == updatedScore.objectId)
        
        print("Updated \"\(updatedScore.className)\" with the following info:")
        print(updatedScore)
    } catch {
        print("Error updating: \(error)")
    }
}
