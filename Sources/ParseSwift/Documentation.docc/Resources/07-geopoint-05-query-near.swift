import Foundation
import ParseSwift

Task {
    do {
        // Create a reference point
        let referencePoint = try ParseGeoPoint(latitude: 40.0, longitude: -30.0)
        
        // Query for GameScores near the reference point
        let query = GameScore.query(near(key: "location", geoPoint: referencePoint))
        
        // Execute the query
        let results = try await query.find()
        
        print("Found \(results.count) GameScore(s) near the reference point")
        
        for score in results {
            if let objectId = score.objectId, let location = score.location {
                print("GameScore \(objectId) at location: \(location)")
            }
        }
    } catch {
        print("Error querying: \(error)")
    }
}
