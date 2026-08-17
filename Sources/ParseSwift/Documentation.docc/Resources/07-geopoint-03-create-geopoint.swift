import Foundation
import ParseSwift

Task {
    do {
        // Create a ParseGeoPoint with latitude and longitude
        let geoPoint = try ParseGeoPoint(latitude: 40.0, longitude: -30.0)

        print("Created GeoPoint: \(geoPoint)")
        print("Latitude: \(geoPoint.latitude)")
        print("Longitude: \(geoPoint.longitude)")
    } catch {
        print("Error creating GeoPoint: \(error)")
    }
}
