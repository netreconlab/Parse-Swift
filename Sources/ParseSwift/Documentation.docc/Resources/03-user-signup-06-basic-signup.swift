import Foundation
import ParseSwift

Task {
    do {
        // Create a new user with username and password
        let newUser = try await User.signup(
            username: "hello",
            password: "TestMePass123^"
        )

        // Verify the user was created successfully
        assert(newUser.objectId != nil)
        assert(newUser.createdAt != nil)
        assert(newUser.username == "hello")

        print("Successfully signed up user: \(newUser)")
    } catch {
        print("Error signing up: \(error)")
    }
}
