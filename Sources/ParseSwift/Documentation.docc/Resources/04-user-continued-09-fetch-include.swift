import Foundation
import ParseSwift

Task {
    do {
        // Get the current user
        let currentUser = try await User.current()
        
        // Fetch user with specific pointer field included
        let fetchedUser = try await currentUser.fetch(includeKeys: ["gameScore"])
        print("Successfully fetched user with gameScore: \(fetchedUser)")
    } catch {
        print("Error fetching user: \(error)")
    }
}
