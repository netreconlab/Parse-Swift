import Foundation
import ParseSwift

Task {
    do {
        // Get the current user and fetch to get the latest data
        var currentUser = try await User.current()
        currentUser = try await currentUser.fetch()
        
        print("Updated current user with relation: \(currentUser)")
        
        // Use the stored ParseRelation property to query related scores
        // The relation was previously saved with GameScore objects
        if let scoresRelation = currentUser.scores {
            let usableStoredRelation = try currentUser.relation(scoresRelation, key: "scores")
            let scores = try await (usableStoredRelation.query() as Query<GameScore>).find()
            
            print("Found related scores from stored ParseRelation: \(scores)")
        } else {
            print("No scores relation found on user")
        }
    } catch {
        print("Error querying stored relation: \(error)")
    }
}
