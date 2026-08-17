import Foundation
import ParseSwift

struct GameScore: ParseObject {
    // These are required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    // Your own custom properties
    var points: Int?

    // Optional - implement your own version of merge
    // for faster decoding after updating your ParseObject
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.points,
                                     original: object) {
            updated.points = object.points
        }
        return updated
    }
}

// It's recommended to place custom initializers in an extension
// to preserve the memberwise initializer
extension GameScore {
    // Custom initializer that accepts an objectId
    init(objectId: String, points: Int) {
        self.objectId = objectId
        self.points = points
    }
}
