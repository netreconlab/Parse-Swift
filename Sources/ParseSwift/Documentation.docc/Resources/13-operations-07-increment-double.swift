import Foundation
import ParseSwift

// Extend GameScore to include a rating field for demonstrating Double increments
struct GameScore: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    var points: Int?
    var name: String?
    var rating: Double?
}

Task {
    do {
        // Create and save a score with a rating
        var score = GameScore()
        score.points = 100
        score.rating = 4.0
        let savedScore = try await score.save()

        // Increment the rating by a decimal amount
        let incrementDoubleOperation = savedScore
            .operation
            .increment("rating", by: 0.5)

        let updatedScore = try await incrementDoubleOperation.save()

        print("Rating incremented by 0.5")
        print("New rating value: \(updatedScore.rating ?? 0)")
    } catch {
        print("Error incrementing rating: \(error)")
    }
}
