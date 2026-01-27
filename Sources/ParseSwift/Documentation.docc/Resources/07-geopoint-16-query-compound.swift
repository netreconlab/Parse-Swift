import Foundation
import ParseSwift

Task {
    do {
        // Create two separate queries
        let query1 = GameScore.query("points" == 50)
        let query2 = GameScore.query("points" == 200)
        
        // Combine queries with OR
        let combinedQuery = GameScore.query(or(queries: [query1, query2]))
        
        // Execute the combined query
        let results = try await combinedQuery.find()
        
        print("Found \(results.count) GameScore(s) with points equal to 50 OR 200")
        
        for score in results {
            if let points = score.points, let location = score.location {
                print("GameScore has \(points) points at location: \(location)")
            }
        }
    } catch {
        print("Error querying: \(error)")
    }
}
