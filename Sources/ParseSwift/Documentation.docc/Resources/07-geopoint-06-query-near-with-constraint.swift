import Foundation
import ParseSwift

Task {
    do {
        // Create a reference point
        let referencePoint = try ParseGeoPoint(latitude: 40.0, longitude: -30.0)

        // Query for GameScores near the reference point with points > 9
        let query = GameScore.query(near(key: "location", geoPoint: referencePoint),
                                   "points" > 9)

        // Execute the query
        let results = try await query.find()

        print("Found \(results.count) GameScore(s) with points > 9 near the reference point")

        for score in results {
            if let objectId = score.objectId,
               let points = score.points,
               let location = score.location {
                print("GameScore \(objectId) has \(points) points at location: \(location)")
            }
        }
    } catch {
        print("Error querying: \(error)")
    }
}
