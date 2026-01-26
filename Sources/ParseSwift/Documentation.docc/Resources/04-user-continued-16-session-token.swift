import Foundation
import ParseSwift

Task {
    do {
        let anonymousUser = try await User.anonymous.login()
        print("Successfully logged in anonymously: \(anonymousUser)")
        
        // Get the session token for the current user
        let sessionToken = try await User.sessionToken()
        print("Session token: \(sessionToken)")
    } catch {
        print("Error: \(error)")
    }
}
