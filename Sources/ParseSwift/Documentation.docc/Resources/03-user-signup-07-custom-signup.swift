import Foundation
import ParseSwift

Task {
    do {
        // Create a user with custom fields
        var user = User()
        user.username = "customUser"
        user.password = "SecurePass456!"
        user.email = "user@example.com"
        user.customKey = "customValue"
        
        let signedUpUser = try await user.signup()
        
        // Verify all fields were saved
        assert(signedUpUser.objectId != nil)
        assert(signedUpUser.username == "customUser")
        assert(signedUpUser.email == "user@example.com")
        assert(signedUpUser.customKey == "customValue")
        
        print("Successfully signed up user with custom fields: \(signedUpUser)")
    } catch {
        print("Error signing up: \(error)")
    }
}
