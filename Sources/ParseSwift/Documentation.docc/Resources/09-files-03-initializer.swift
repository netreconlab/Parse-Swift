import Foundation
import ParseSwift

// Create your own value typed ParseObject
struct GameScore: ParseObject {
    // These are required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    // Your own properties
    var points: Int? = 0
    var profilePicture: ParseFile?

    // Optional - implement your own version of merge for faster decoding
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.points, original: object) {
            updated.points = object.points
        }
        if updated.shouldRestoreKey(\.profilePicture, original: object) {
            updated.profilePicture = object.profilePicture
        }
        return updated
    }
}

// It's recommended to place custom initializers in an extension
extension GameScore {
    // Custom initializer
    init(points: Int) {
        self.points = points
    }
}
