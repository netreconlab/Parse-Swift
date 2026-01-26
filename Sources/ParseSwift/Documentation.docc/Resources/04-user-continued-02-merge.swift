import Foundation
import ParseSwift

struct User: ParseUser {
    // These are required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    // These are required by ParseUser
    var username: String?
    var email: String?
    var emailVerified: Bool?
    var password: String?
    var authData: [String: [String: String]?]?

    // Your custom properties
    var customKey: String?
    var gameScore: GameScore?

    // Optional - implement your own version of merge
    // for faster decoding after updating your ParseUser
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.customKey, original: object) {
            updated.customKey = object.customKey
        }
        if updated.shouldRestoreKey(\.gameScore, original: object) {
            updated.gameScore = object.gameScore
        }
        return updated
    }
}
