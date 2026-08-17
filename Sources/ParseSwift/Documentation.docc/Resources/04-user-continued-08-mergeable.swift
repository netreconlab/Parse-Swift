import Foundation
import ParseSwift

Task {
    do {
        // Get the current user
        var currentUser = try await User.current()

        // Use mergeable to update properties
        currentUser = currentUser.mergeable
        currentUser.customKey = "myCustomValue"

        // Save the changes
        let updatedUser = try await currentUser.save()
        print("Successfully updated user: \(updatedUser)")
    } catch {
        print("Failed to update user: \(error)")
    }
}
