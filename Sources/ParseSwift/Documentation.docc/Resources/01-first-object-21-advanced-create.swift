import Foundation
import ParseSwift

Task {
    do {
        // Create a polygon using geographic coordinates
        // A simple square polygon for demonstration
        let points = [
            try ParseGeoPoint(latitude: 40.0, longitude: -75.0),  // Southwest corner
            try ParseGeoPoint(latitude: 40.0, longitude: -74.0),  // Southeast corner
            try ParseGeoPoint(latitude: 41.0, longitude: -74.0),  // Northeast corner
            try ParseGeoPoint(latitude: 41.0, longitude: -75.0),  // Northwest corner
            try ParseGeoPoint(latitude: 40.0, longitude: -75.0)   // Close the polygon
        ]
        
        let polygon = try ParsePolygon(points)
        
        // Create binary data using ParseBytes
        let data = "hello world".data(using: .utf8)!
        let bytes = ParseBytes(data: data)
        
        print("Created polygon with \(polygon.coordinates.count) points")
        print("Created bytes with \(bytes.data.count) bytes")
    } catch {
        print("Error creating advanced types: \(error)")
    }
}
