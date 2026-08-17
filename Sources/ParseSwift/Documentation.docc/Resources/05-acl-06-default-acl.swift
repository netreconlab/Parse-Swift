import Foundation
import ParseSwift

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

Task {
    do {
        // Create a restrictive default ACL for all new ParseObjects
        var defaultACL = ParseACL()
        defaultACL.publicRead = false
        defaultACL.publicWrite = false

        // Set as default ACL with access for current user
        // The current user will automatically get read and write access
        let savedACL = try await ParseACL.setDefaultACL(
            defaultACL,
            withAccessForCurrentUser: true
        )

        print("Default ACL set successfully")
        print("Public read: \(savedACL.publicRead)")
        print("Public write: \(savedACL.publicWrite)")
    } catch {
        print("Error setting default ACL: \(error)")
    }
}
