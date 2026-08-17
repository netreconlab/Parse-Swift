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
    var tags: [String]?

    // Optional - implement your own version of merge
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
        if updated.shouldRestoreKey(\.tags,
                                     original: object) {
            updated.tags = object.tags
        }
        return updated
    }
}

extension GameScore {
    init(points: Int, name: String? = nil, tags: [String]? = nil) {
        self.points = points
        self.name = name
        self.tags = tags
    }
}
