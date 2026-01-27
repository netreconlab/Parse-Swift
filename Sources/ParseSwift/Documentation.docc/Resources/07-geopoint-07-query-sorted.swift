import Foundation
import ParseSwift

Task {
    do {
        // Create a reference point
        let referencePoint = try ParseGeoPoint(latitude: 40.0, longitude: -30.0)
        
        // Query for GameScores near the reference point, sorted by points
        var query = GameScore.query(near(key: "location", geoPoint: referencePoint))
        query = query.order([.descending("points")])
        
        // Execute the query
        let results = try await query.find()
        
        print("Found \(results.count) GameScore(s), sorted by points (descending)")
        
        for score in results {
            if let points = score.points {
                print("GameScore with \(points) points")
            }
        }
    } catch {
        print("Error querying: \(error)")
    }
}
