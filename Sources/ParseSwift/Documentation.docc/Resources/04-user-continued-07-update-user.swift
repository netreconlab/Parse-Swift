import Foundation
import ParseSwift

Task {
    do {
        // Get the current user and update custom fields
        var currentUser = try await User.current()
            .set(\.customKey, to: "myCustom")
            .set(\.gameScore, to: GameScore(points: 12))
        
        // Save the updated user
        let updatedUser = try await currentUser.save()
        print("Successfully saved custom fields: \(updatedUser)")
    } catch {
        print("Failed to update user: \(error)")
    }
}
