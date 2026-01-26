import Foundation
import ParseSwift

Task {
    // First, attempt to sign up a user (ignore if already exists)
    do {
        _ = try await User.signup(
            username: "duplicateUser",
            password: "SecurePass123!"
        )
    } catch {
        // User may already exist from previous run, that's okay
        print("First user may already exist: \(error)")
    }
    
    // Now attempt to sign up with the same username - this should fail
    do {
        let user2 = try await User.signup(
            username: "duplicateUser",
            password: "AnotherPass456!"
        )
        
        print("Second user created unexpectedly: \(user2)")
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
