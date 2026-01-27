import Foundation
import ParseSwift

Task {
    do {
        let anonymousUser = try await User.anonymous.login()
        print("Successfully logged in anonymously: \(anonymousUser)")
        
        // Get the session token for the current user
        let sessionToken = try await User.sessionToken()
        print("Successfully retrieved session token for current user.")
    } catch {
        print("Error: \(error)")
    }
}
