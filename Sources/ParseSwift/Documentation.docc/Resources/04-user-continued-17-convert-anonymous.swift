import Foundation
import ParseSwift

Task {
    do {
        // Login anonymously first
        _ = try await User.anonymous.login()

        // Convert the anonymous user to a real user
        var currentUser = try await User.current()
        currentUser.username = "realuser"
        currentUser.password = "HelloMePass123^"

        let convertedUser = try await currentUser.signup()
        print("Successfully converted anonymous user: \(convertedUser)")

        // Get the new session token
        let sessionToken = try await User.sessionToken()
        print("New session token obtained successfully.")
    } catch {
        print("Error converting user: \(error)")
    }
}
