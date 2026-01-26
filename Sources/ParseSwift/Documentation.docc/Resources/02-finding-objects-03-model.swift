import Foundation
import ParseSwift

struct GameScore: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    // Your own properties
    var points: Int?
    var timeStamp: Date?
    var oldScore: Int?
    var isHighest: Bool?

    // Optional - implement your own version of merge
    // for faster decoding after updating your ParseObject
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.points,
                                     original: object) {
            updated.points = object.points
        }
        if updated.shouldRestoreKey(\.timeStamp,
                                     original: object) {
            updated.timeStamp = object.timeStamp
        }
        if updated.shouldRestoreKey(\.oldScore,
                                     original: object) {
            updated.oldScore = object.oldScore
        }
        if updated.shouldRestoreKey(\.isHighest,
                                     original: object) {
            updated.isHighest = object.isHighest
        }
        return updated
    }
}
