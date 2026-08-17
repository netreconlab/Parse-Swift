import Foundation
import ParseSwift

Task {
    do {
        // Create a location to check
        let location = try ParseGeoPoint(latitude: 40.0, longitude: -30.0)

        // Query for GameScores whose fence polygon contains the location
        let query = GameScore.query(polygon("fence", contains: location))

        // Execute the query
        let results = try await query.find()

        print("Found \(results.count) GameScore(s) whose fence contains the location")

        for score in results {
            if let points = score.points, let fence = score.fence {
                print("GameScore with \(points) points has fence: \(fence)")
                print("Fence contains location: \(location)")
            }
        }
    } catch {
        print("Error querying: \(error)")
    }
}
