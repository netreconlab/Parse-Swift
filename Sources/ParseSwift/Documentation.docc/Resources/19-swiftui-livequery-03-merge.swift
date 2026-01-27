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
        if updated.shouldRestoreKey(\.location,
                                     original: object) {
            updated.location = object.location
        }
        return updated
    }
}
