import Foundation
import ParseSwift

struct GameScore: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?
    var points: Int?

    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.points, original: object) {
            updated.points = object.points
        }
        return updated
    }
}

extension GameScore {
    init(points: Int) {
        self.points = points
    }
}

// Define a User type that conforms to ParseUser
struct User: ParseUser {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    var username: String?
    var email: String?
    var emailVerified: Bool?
    var password: String?
    var authData: [String: [String: String]?]?
}

var score = GameScore(points: 100)

Task {
    do {
        // Get the current user
        let currentUser = try await User.current()

        guard let userId = currentUser.objectId else {
            print("Current user has no objectId")
            return
        }

        // Create an ACL with user-specific permissions
        var acl = ParseACL()

        // Grant read and write access to a specific user
        acl.setReadAccess(objectId: userId, value: true)
        acl.setWriteAccess(objectId: userId, value: true)

        // Deny public access
        acl.publicRead = false
        acl.publicWrite = false

        score.ACL = acl
        let savedScore = try await score.save()

        print("Saved score with user-specific permissions")
        print("User \(userId) has read access: \(savedScore.ACL?.getReadAccess(objectId: userId) ?? false)")
        print("User \(userId) has write access: \(savedScore.ACL?.getWriteAccess(objectId: userId) ?? false)")
    } catch {
        print("Error: \(error)")
    }
}
