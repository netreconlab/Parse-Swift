import Foundation
import ParseSwift

struct GameData: ParseObject {
    // These are required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    // Your own properties
    var fence: ParsePolygon?
    // ParseBytes needs to be a part of the original schema
    // or else you will need your primaryKey to force an upgrade
    var bytes: ParseBytes?
    
    // Optional - implement your own version of merge
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.fence, original: object) {
            updated.fence = object.fence
        }
        if updated.shouldRestoreKey(\.bytes, original: object) {
            updated.bytes = object.bytes
        }
        return updated
    }
}

extension GameData {
    init(bytes: ParseBytes?, fence: ParsePolygon) {
        self.bytes = bytes
        self.fence = fence
    }
}
