import Foundation
import ParseSwift

Task {
    do {
        // Create a polygon from an array of GeoPoints
        let points: [ParseGeoPoint] = [
            try .init(latitude: 35.0, longitude: -30.0),
            try .init(latitude: 42.0, longitude: -35.0),
            try .init(latitude: 42.0, longitude: -20.0)
        ]
        
        let polygon = try ParsePolygon(points)
        
        print("Created polygon with \(polygon.coordinates.count) points")
        print("Polygon: \(polygon)")
    } catch {
        print("Error creating polygon: \(error)")
    }
}
