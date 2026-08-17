import Foundation
import ParseSwift

Task {
    do {
        // Sign up a new user
        let newUser = try await User.signup(
            username: "hello",
            password: "TestMePass123^"
        )

        // Retrieve the current user from local storage
        let currentUser = try await User.current()

        // Verify they match
        if currentUser.hasSameObjectId(as: newUser) {
            print("Current user matches signed up user")
            print("Username: \(currentUser.username ?? "N/A")")
        } else {
            print("Error: Current user does not match signed up user")
        }
    } catch {
        print("Error: \(error)")
    }
}
