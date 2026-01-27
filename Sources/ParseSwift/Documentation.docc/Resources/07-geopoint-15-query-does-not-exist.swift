import Foundation
import ParseSwift

Task {
    do {
        // Query for GameScores where location does not exist (is undefined)
        let query = GameScore.query("points" > 50, doesNotExist(key: "location"))

        // Execute the query
        let results = try await query.find()

        print("Found \(results.count) GameScore(s) with points > 50 that have no location")

        for score in results {
            if let points = score.points {
                print("GameScore has \(points) points with no location")
            }
        }
    } catch {
        print("Error querying: \(error)")
    }
}
