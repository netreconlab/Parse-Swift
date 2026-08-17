import Foundation
import ParseSwift

struct GameScore: ParseObject {
    // Required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    // Custom properties
    var points: Int?
    var location: ParseGeoPoint?

    // Optional - implement your own version of merge for faster decoding
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.points, original: object) {
            updated.points = object.points
        }
        if updated.shouldRestoreKey(\.location, original: object) {
            updated.location = object.location
        }
        return updated
    }
}

// Custom initializer
extension GameScore {
    init(points: Int) {
        self.points = points
    }
}
