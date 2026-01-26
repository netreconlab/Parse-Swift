import Foundation
import ParseSwift

Task {
    do {
        // First sign up a user
        let newUser = try await User.signup(
            username: "verifyUser",
            password: "TestMePass123^"
        )
        
        // Attempt to verify with incorrect password
        let verifiedUser = try await User.verifyPassword(
            password: "wrongPassword",
            usingPost: true
        )
        
        print("User verified (this shouldn't happen): \(verifiedUser)")
    } catch {
        // This error is expected when using wrong password
        print("Password verification failed as expected: \(error)")
    }
}
