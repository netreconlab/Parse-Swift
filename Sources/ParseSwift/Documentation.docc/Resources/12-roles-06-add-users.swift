import Foundation
import ParseSwift

Task {
    do {
        // Get the current user
        let currentUser = try await User.current()

        // ParseRoles have ParseRelations that relate them to ParseUser and ParseRole objects
        // The ParseUser relations can be accessed using `users`
        // Add users to the relation and save it
		let role = try await savedRole!.users?.add([currentUser]).save()
        guard let role != nil else {
            print("Error: could not add user to role")
            return
        }

        print("Users added to role successfully")
        print("Check \"users\" field in your \"Role\" class in Parse Dashboard.")
    } catch {
        print("Error adding users to role: \(error)")
    }
}
