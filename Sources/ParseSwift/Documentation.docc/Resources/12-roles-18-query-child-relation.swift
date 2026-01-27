import Foundation
import ParseSwift

Task {
    do {
        // Get the current user
        let currentUser = try await User.current()

        // Query from the child perspective using queryRelations
        let query = try GameScore.queryRelations("scores", parent: currentUser)
        let scores = try await query.find()

        print("Found related scores from child: \(scores)")
    } catch {
        print("Error querying child relations: \(error)")
    }
}
