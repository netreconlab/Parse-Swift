import Foundation
import ParseSwift

Task {
    do {
        // Get the current user
        let currentUser = try await User.current()

        // Remove users from the role
        try await savedRole!.users?.remove([currentUser]).save()

        print("User removed from role successfully")
        print("Check \"users\" field in your \"Role\" class in Parse Dashboard.")
    } catch {
        print("Error removing users from role: \(error)")
    }
}
