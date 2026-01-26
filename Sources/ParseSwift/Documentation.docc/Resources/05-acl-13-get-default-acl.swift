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
        // Retrieve the current default ACL
        let currentDefaultACL = try await ParseACL.defaultACL()
        
        print("Current default ACL:")
        print("Public read: \(currentDefaultACL.publicRead)")
        print("Public write: \(currentDefaultACL.publicWrite)")
    } catch {
        print("Error getting default ACL: \(error)")
    }
}
