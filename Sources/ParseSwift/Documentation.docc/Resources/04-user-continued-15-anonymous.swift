import Foundation
import ParseSwift

Task {
    do {
        let anonymousUser = try await User.anonymous.login()
        print("Successfully logged in anonymously: \(anonymousUser)")

        // Verify the current user is stored locally
        let currentUser = try await User.current()
        print("Current anonymous user: \(currentUser)")
    } catch {
        print("Error logging in anonymously: \(error)")
    }
}
