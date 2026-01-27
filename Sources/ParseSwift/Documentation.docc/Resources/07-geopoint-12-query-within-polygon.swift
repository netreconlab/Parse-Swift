import Foundation
import ParseSwift

Task {
    do {
        // Create a ParsePolygon
        let polygonPoints: [ParseGeoPoint] = [
            try .init(latitude: 35.0, longitude: -30.0),
            try .init(latitude: 42.0, longitude: -35.0),
            try .init(latitude: 42.0, longitude: -20.0)
        ]
        let polygon = try ParsePolygon(polygonPoints)
        
        // Query for GameScores whose location is within the polygon
        let query = GameScore.query(geoPoint("location", within: polygon))
        
        // Execute the query
        let results = try await query.find()
        
        print("Found \(results.count) GameScore(s) within the polygon")
        
        for score in results {
            if let location = score.location {
                print("Location \(location) is within polygon: \(polygon)")
            }
        }
    } catch {
        print("Error querying: \(error)")
    }
}
