import Foundation
import ParseSwift

Task {
    do {
        try await User.passwordReset(email: "hello@parse.org")
        print("Successfully requested password reset")
    } catch {
        print("Error requesting password reset: \(error)")
    }
}
