import Foundation
import ParseSwift

// Create a GameScore model to use with relations
struct GameScore: ParseObject {
    // Required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    // Your own properties
    var points: Int?

    // Optional - implement your own version of merge
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.points,
                                     original: object) {
            updated.points = object.points
        }
        return updated
    }
}

// Custom initializer in an extension
extension GameScore {
    init(points: Int) {
        self.points = points
    }
}
