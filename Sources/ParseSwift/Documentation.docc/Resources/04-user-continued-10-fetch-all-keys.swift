import Foundation
import ParseSwift

Task {
    do {
        // Get the current user
        let currentUser = try await User.current()
        
        // Fetch user with all pointer fields included using ["*"]
        let fetchedUser = try await currentUser.fetch(includeKeys: ["*"])
        print("Successfully fetched user with all pointer fields: \(fetchedUser)")
    } catch {
        print("Error fetching user: \(error)")
    }
}
