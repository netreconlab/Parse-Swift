import Foundation
import ParseSwift

var score = GameScore(points: 10)

Task {
    do {
        // Create a location for the object
        score.location = try ParseGeoPoint(latitude: 40.0, longitude: -30.0)

        // Create a polygon fence
        let points: [ParseGeoPoint] = [
            try .init(latitude: 35.0, longitude: -30.0),
            try .init(latitude: 42.0, longitude: -35.0),
            try .init(latitude: 42.0, longitude: -20.0)
        ]
        score.fence = try ParsePolygon(points)

        // Save the object with both location and fence
        let savedScore = try await score.save()

        if let fence = savedScore.fence {
            print("Saved polygon fence: \(fence)")
            print("Fence coordinates: \(fence.coordinates)")
        }
    } catch {
        print("Error saving: \(error)")
    }
}
