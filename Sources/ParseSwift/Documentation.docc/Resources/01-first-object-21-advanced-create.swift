import Foundation
import ParseSwift

Task {
    do {
        // Create a polygon using geographic coordinates
        // First point must match the last point to close the polygon
        let points = [
            try ParseGeoPoint(latitude: 42.631655189280224, longitude: -83.78406753121705),
            try ParseGeoPoint(latitude: 42.633047793854814, longitude: -83.75333640366955),
            try ParseGeoPoint(latitude: 42.61625254348911, longitude: -83.75149921669944),
            try ParseGeoPoint(latitude: 42.61526926650296, longitude: -83.78161794858735),
            try ParseGeoPoint(latitude: 42.631655189280224, longitude: -83.78406753121705)
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
