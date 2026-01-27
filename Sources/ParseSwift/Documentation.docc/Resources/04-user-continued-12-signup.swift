import Foundation
import ParseSwift

// Create a user with custom fields
var newUser = User(username: "parse", password: "aPassword123*", email: "parse@parse.com")
newUser.customKey = "mind"

Task {
    do {
        let signedUpUser = try await newUser.signup()
        
        // Verify the current user is stored locally
        let currentUser = try await User.current()
        assert(currentUser.hasSameObjectId(as: signedUpUser))
        
        print("Successfully signed up as user: \(signedUpUser)")
    } catch {
        print("Error signing up: \(error)")
    }
}
