import Foundation
import ParseSwift

Task {
    do {
        try await User.logout()
        print("Successfully logged out")
    } catch {
        print("Error logging out: \(error)")
    }
}
