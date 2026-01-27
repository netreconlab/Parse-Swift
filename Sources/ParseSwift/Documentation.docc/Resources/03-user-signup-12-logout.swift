import Foundation
import ParseSwift

Task {
    do {
        // Sign up a user
        let newUser = try await User.signup(
            username: "hello",
            password: "TestMePass123^"
        )
        print("User signed up: \(newUser.username ?? "N/A")")

        // Log out the user
        try await User.logout()
        print("User logged out successfully")

        // Verify no current user exists
        do {
            let currentUser = try await User.current()
            print("Current user still exists: \(currentUser.username ?? "N/A")")
        } catch {
            print("No current user after logout (expected)")
        }
    } catch {
        print("Error: \(error)")
    }
}
