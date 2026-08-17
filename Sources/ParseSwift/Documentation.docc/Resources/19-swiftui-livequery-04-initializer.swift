import Foundation
import ParseSwift
import SwiftUI

struct GameScore: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?
    var points: Int? = 0
    var location: ParseGeoPoint?
    var name: String?

    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.points,
                                     original: object) {
            updated.points = object.points
        }
        if updated.shouldRestoreKey(\.name,
                                     original: object) {
            updated.name = object.name
        }
        if updated.shouldRestoreKey(\.location,
                                     original: object) {
            updated.location = object.location
        }
        return updated
    }
}

// It's recommended to place custom initializers in an extension
// to preserve the memberwise initializer
extension GameScore {
    // Custom initializer
    init(name: String, points: Int) {
        self.name = name
        self.points = points
    }
}
