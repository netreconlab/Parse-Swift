import Foundation
import ParseSwift

Task {
    do {
        // Attempt to verify with incorrect password
        let verifiedUser = try await User.verifyPassword(
            password: "wrongPassword",
            usingPost: false
        )
        
        print("User verified (this shouldn't happen): \(verifiedUser)")
    } catch {
        // This error is expected when using wrong password
        print("Password verification failed as expected: \(error)")
    }
}
