import Foundation
import ParseSwift

Task {
    do {
        // Attempt to sign up with duplicate username
        let user1 = try await User.signup(
            username: "duplicateUser",
            password: "SecurePass123!"
        )
        
        // This should fail with a duplicate username error
        let user2 = try await User.signup(
            username: "duplicateUser",
            password: "AnotherPass456!"
        )
        
        print("Second user created: \(user2)")
    } catch let error as ParseError {
        // Handle specific Parse errors
        switch error.code {
        case .usernameTaken:
            print("Error: Username already exists")
        case .passwordMissing:
            print("Error: Password is required")
        default:
            print("Signup error: \(error.message)")
        }
    } catch {
        print("Unexpected error: \(error)")
    }
}
