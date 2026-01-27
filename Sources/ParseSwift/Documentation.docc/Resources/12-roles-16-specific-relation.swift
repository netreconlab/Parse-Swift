import Foundation
import ParseSwift

Task {
    do {
        // Get the current user
        let currentUser = try await User.current()

        // Create a specific relation by key name
        let score1 = GameScore(points: 53)
        let specificRelation = try currentUser.relation("scores", child: score1)

        print("Created specific relation for key: scores")

        // You can also use this alternative syntax:
        // let currentUser = try await User.current()
        // let specificRelation = try currentUser.relation("scores", object: GameScore.self)
    } catch {
        print("Error creating specific relation: \(error)")
    }
}
