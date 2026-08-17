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
    var name: String?

    // Optional - implement your own version of merge
    // for faster decoding after updating your ParseObject
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
        return updated
    }
}

// It's recommended to place custom initializers in an extension
// to preserve the memberwise initializer
extension GameScore {
    init(points: Int, name: String? = nil) {
        self.points = points
        self.name = name
    }
}
