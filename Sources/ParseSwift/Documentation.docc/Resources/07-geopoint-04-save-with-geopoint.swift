import Foundation
import ParseSwift

var score = GameScore(points: 10)

Task {
    do {
        // Assign a location to the GameScore
        score.location = try ParseGeoPoint(latitude: 40.0, longitude: -30.0)

        // Save the object with the GeoPoint
        let savedScore = try await score.save()

        // Verify the object was saved successfully with location
        assert(savedScore.objectId != nil)
        assert(savedScore.location != nil)

        if let location = savedScore.location {
            print("Saved location: \(location)")
            print("Latitude: \(location.latitude), Longitude: \(location.longitude)")
        }
    } catch {
        print("Error saving: \(error)")
    }
}
