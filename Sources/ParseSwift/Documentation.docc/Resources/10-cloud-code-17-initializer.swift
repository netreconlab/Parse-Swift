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

    // Optional: Implement merge method for better performance
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.points,
                                     original: object) {
            updated.points = object.points
        }
        return updated
    }
}

// Extension for custom initializer
extension GameScore {
    init(points: Int) {
        self.points = points
    }
}
