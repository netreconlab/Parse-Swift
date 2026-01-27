import Foundation
import ParseSwift

Task {
    do {
        // Define a polygon area using an array of GeoPoints
        let polygonPoints: [ParseGeoPoint] = [
            try .init(latitude: 35.0, longitude: -30.0),
            try .init(latitude: 42.0, longitude: -35.0),
            try .init(latitude: 42.0, longitude: -20.0)
        ]

        // Query for GameScores whose location is within the polygon
        let query = GameScore.query(geoPoint("location", within: polygonPoints))

        // Execute the query
        let results = try await query.find()

        print("Found \(results.count) GameScore(s) within the polygon")

        for score in results {
            if let points = score.points, let location = score.location {
                print("GameScore with \(points) points at location: \(location)")
            }
        }
    } catch {
        print("Error querying: \(error)")
    }
}
