import Foundation
import ParseSwift

struct User: ParseUser {
    // Required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    // Required by ParseUser
    var username: String?
    var email: String?
    var emailVerified: Bool?
    var password: String?
    var authData: [String: [String: String]?]?

    // Your custom keys
    var customKey: String?
}

// Extend User to add a ParseRelation for GameScore objects
extension User {
    // Add a computed property to access the scores relation
    // The relation stores references to GameScore objects
    // ParseRelation is generic over the parent type (User), not the child type
    var scores: ParseRelation<User>? {
        get { self["scores"] }
        set { self["scores"] = newValue }
    }
}
