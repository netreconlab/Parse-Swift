import Foundation
import ParseSwift

// Your specific User value type.
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
}

// Create your own value typed `ParseObject`.
struct GameScore: ParseObject {
    // These are required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    // Your own properties.
    var points: Int?
    var level: Int?
    var data: ParseBytes?
    var owner: User?
    var rivals: [User]?
}
