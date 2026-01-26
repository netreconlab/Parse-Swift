import Foundation
import ParseSwift

Task {
    do {
        let loggedInUser = try await User.login(username: "hello", password: "TestMePass123^")
        
        // Verify the current user is stored locally
        let currentUser = try await User.current()
        assert(currentUser.hasSameObjectId(as: loggedInUser))
        
        print("Successfully logged in as user: \(loggedInUser)")
        print("Current user matches logged in user")
    } catch {
        print("Error logging in: \(error)")
    }
}
