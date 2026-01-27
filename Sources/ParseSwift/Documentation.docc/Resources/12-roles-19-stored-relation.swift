import Foundation
import ParseSwift

Task {
    do {
        // Get the current user and fetch to get the latest data
        var currentUser = try await User.current()
        currentUser = try await currentUser.fetch()
        
        print("Updated current user with relation: \(currentUser)")
        
        // Use the stored ParseRelation property
        let usableStoredRelation = try currentUser.relation(currentUser.scores, key: "scores")
        
        // Query using the stored relation
        let scores = try await (usableStoredRelation.query() as Query<GameScore>).find()
        
        print("Found related scores from stored ParseRelation: \(scores)")
    } catch {
        print("Error querying stored relation: \(error)")
    }
}
