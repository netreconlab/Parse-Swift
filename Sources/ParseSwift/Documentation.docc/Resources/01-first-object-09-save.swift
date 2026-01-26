import Foundation
import ParseSwift

let score = GameScore(points: 10)

Task {
    do {
        let savedScore = try await score.save()
        
        // Verify the object was saved successfully
        assert(savedScore.objectId != nil)
        assert(savedScore.createdAt != nil)
        assert(savedScore.updatedAt != nil)
        assert(savedScore.points == 10)
        
        print("Saved \"\(savedScore.className)\" with the following info:")
        print(savedScore)
    } catch {
        print("Error saving: \(error)")
    }
}
