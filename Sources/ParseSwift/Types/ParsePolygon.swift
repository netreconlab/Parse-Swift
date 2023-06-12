//
//  ParsePolygon.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/9/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

/**
 `ParsePolygon` is used to create a polygon that represents the coordinates
 that may be associated with a key in a `ParseObject` or used as a reference point
 for geo queries. This allows proximity-based queries on the key.
*/
public struct ParsePolygon: ParseTypeable, Hashable {
    private let __type: String = "Polygon" // swiftlint:disable:this identifier_name
    public let coordinates: [ParseGeoPoint]

    enum CodingKeys: String, CodingKey {
        case __type // swiftlint:disable:this identifier_name
        case coordinates
    }

    /**
      Create new `ParsePolygon` instance with coordinates.
       - parameter coordinates: An array of geopoints that make the polygon.
       - throws: An error of type `ParseError`.
     */
    public init(_ coordinates: [ParseGeoPoint]) throws {
        self.coordinates = coordinates
        try validate()
    }

    /**
      Create new `ParsePolygon` instance with a variadic amount of coordinates.
       - parameter coordinates: variadic amount of zero or more `ParseGeoPoint`'s.
       - throws: An error of type `ParseError`.
     */
    public init(_ coordinates: ParseGeoPoint...) throws {
        try self.init(coordinates)
    }

    func validate() throws {
        if coordinates.count < 3 {
            throw ParseError(code: .otherCause,
                             message: "Polygon must have at least 3 ParseGeoPoint's or Points")
        }
    }

    /**
      Determines if a `ParsePolygon` containes a point.
       - parameter point: The point to check.
     */
    public func containsPoint(_ point: ParseGeoPoint) -> Bool {
        var minX = coordinates[0].longitude
        var maxX = coordinates[0].longitude
        var minY = coordinates[0].latitude
        var maxY = coordinates[0].latitude

        var modifiedCoordinates = coordinates
        modifiedCoordinates.removeFirst()
        for coordinate in modifiedCoordinates {
            minX = Swift.min(coordinate.longitude, minX)
            maxX = Swift.max(coordinate.longitude, maxX)
            minY = Swift.min(coordinate.latitude, minY)
            maxY = Swift.max(coordinate.latitude, maxY)
        }

        // Check if outside of the polygon
        if point.longitude < minX ||
            point.longitude > maxX ||
            point.latitude < minY ||
            point.latitude > maxY {
            return false
        }

        modifiedCoordinates = coordinates

        // Check if intersects polygon
        var otherIndex = coordinates.count - 1
        for (index, coordinate) in coordinates.enumerated() {
            let startX = coordinate.longitude
            let startY = coordinate.latitude
            let endX = coordinates[otherIndex].longitude
            let endY = coordinates[otherIndex].latitude
            let startYComparison = startY > point.latitude
            let endYComparison = endY > point.latitude
            if startYComparison != endYComparison &&
                point.longitude < ((endX - startX) * (point.latitude - startY)) / (endY - startY) + startX {
                return true
            }
            if index == 0 {
                otherIndex = index
            } else {
                otherIndex += 1
            }
        }
        return false
    }
}

// MARK: Encodable

extension ParsePolygon {

    public func encode(to encoder: Encoder) throws {
        try validate()
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(__type, forKey: .__type)
        var nestedUnkeyedContainer = container.nestedUnkeyedContainer(forKey: .coordinates)
        try coordinates.forEach {
            try nestedUnkeyedContainer.encode([$0.longitude, $0.latitude])
        }
    }

}

// MARK: Decodable

extension ParsePolygon {

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        var decodedCoordinates = [ParseGeoPoint]()
        let points = try values.decode([[Double]].self, forKey: .coordinates)
        try points.forEach {
            if $0.count == 2 {
                guard let latitude = $0.last,
                      let longitude = $0.first else {
                    throw ParseError(code: .otherCause, message: "Could not decode ParsePolygon: \(points)")
                }
                decodedCoordinates.append(try ParseGeoPoint(latitude: latitude,
                                                            longitude: longitude))
            } else {
                throw ParseError(code: .otherCause, message: "Could not decode ParsePolygon: \(points)")
            }
        }
        coordinates = decodedCoordinates
        try validate()
    }

}
