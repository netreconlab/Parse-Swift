import Foundation
import ParseSwift

Task {
    do {
        // Get the current user
        let currentUser = try await User.current()

        // Create a specific relation
        let score1 = GameScore(points: 53)
        let specificRelation = try currentUser.relation("scores", child: score1)

        // Query the relation to get all related objects
        let query: Query<GameScore> = try specificRelation.query()
        let scores = try await query.find()

        print("Found related scores: \(scores)")
    } catch {
        print("Error querying relation: \(error)")
    }
}
