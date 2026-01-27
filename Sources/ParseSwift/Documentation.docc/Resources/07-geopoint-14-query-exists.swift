import Foundation
import ParseSwift

Task {
    do {
        // Query for GameScores where location exists (is not undefined)
        let query = GameScore.query("points" > 9, exists(key: "location"))
        
        // Execute the query
        let results = try await query.find()
        
        print("Found \(results.count) GameScore(s) with points > 9 that have a location")
        
        for score in results {
            if let points = score.points, let location = score.location {
                print("GameScore has \(points) points with location: \(location)")
            }
        }
    } catch {
        print("Error querying: \(error)")
    }
}
