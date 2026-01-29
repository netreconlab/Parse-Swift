import Foundation
import ParseSwift

Task {
    do {
        // Create a simple square polygon
        let points = [
            try ParseGeoPoint(latitude: 40.0, longitude: -75.0),  // Southwest corner
            try ParseGeoPoint(latitude: 40.0, longitude: -74.0),  // Southeast corner
            try ParseGeoPoint(latitude: 41.0, longitude: -74.0),  // Northeast corner
            try ParseGeoPoint(latitude: 41.0, longitude: -75.0),  // Northwest corner
            try ParseGeoPoint(latitude: 40.0, longitude: -75.0)   // Close the polygon
        ]
        let polygon = try ParsePolygon(points)

        // Create binary data
        let data = "hello world".data(using: .utf8)!
        let bytes = ParseBytes(data: data)

        // Create and save the GameData object
        var gameData = GameData(bytes: bytes, fence: polygon)
        gameData = try await gameData.save()

        print("Successfully saved GameData with polygon and bytes:")
        print(gameData)
    } catch {
        print("Error saving: \(error)")
    }
}
