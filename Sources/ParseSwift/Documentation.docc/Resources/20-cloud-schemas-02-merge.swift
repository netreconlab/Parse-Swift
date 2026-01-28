import Foundation
import ParseSwift

struct GameScore: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    var points: Int?
    var level: Int?
    var data: ParseBytes?
    var owner: User?
    var rivals: [User]?

    // Optional - implement your own version of merge
    // for faster decoding after updating your `ParseObject`.
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.points, original: object) {
            updated.points = object.points
        }
        if updated.shouldRestoreKey(\.level, original: object) {
            updated.level = object.level
        }
        if updated.shouldRestoreKey(\.data, original: object) {
            updated.data = object.data
        }
        if updated.shouldRestoreKey(\.owner, original: object) {
            updated.owner = object.owner
        }
        if updated.shouldRestoreKey(\.rivals, original: object) {
            updated.rivals = object.rivals
        }
        return updated
    }
}
