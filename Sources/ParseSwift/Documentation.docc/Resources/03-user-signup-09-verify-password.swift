import Foundation
import ParseSwift

Task {
    do {
        // First sign up a user
        let newUser = try await User.signup(
            username: "hello",
            password: "TestMePass123^"
        )
        
        // Verify the password
        // For production, usingPost should be set to true so credentials are sent in the request body
        let verifiedUser = try await User.verifyPassword(
            password: "TestMePass123^",
            usingPost: true
        )
        
        print("Password verified successfully for user: \(verifiedUser.username ?? "N/A")")
    } catch {
        print("Error verifying password: \(error)")
    }
}
