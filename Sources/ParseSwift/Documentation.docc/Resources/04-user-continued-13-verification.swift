import Foundation
import ParseSwift

Task {
    do {
        try await User.verificationEmail(email: "hello@parse.org")
        print("Successfully requested verification email be sent")
    } catch {
        print("Error requesting verification email: \(error)")
    }
}
