import Foundation
import ParseSwift

Task {
    do {
        // Create a polygon representing Detroit area
        let detroitPoints = [
            try ParseGeoPoint(latitude: 42.631655189280224, longitude: -83.78406753121705),
            try ParseGeoPoint(latitude: 42.633047793854814, longitude: -83.75333640366955),
            try ParseGeoPoint(latitude: 42.61625254348911, longitude: -83.75149921669944),
            try ParseGeoPoint(latitude: 42.61526926650296, longitude: -83.78161794858735),
            try ParseGeoPoint(latitude: 42.631655189280224, longitude: -83.78406753121705)
        ]
        
        let detroit = try ParsePolygon(detroitPoints)
        
        // Create binary data
        let bytes = ParseBytes(data: "hello world".data(using: .utf8)!)
        
        print("Created ParsePolygon and ParseBytes")
    } catch {
        print("Error creating advanced types: \(error)")
    }
}
