import Foundation
import ParseSwift

Task {
    do {
        // Query the users relation to retrieve all users in the role
        let query: Query<User>? = try savedRole!.users?.query()
        let relatedUsers = try await query?.find()

        print("""
            The following users are part of the
            \"\(String(describing: savedRole!.name))\" role: \(relatedUsers ?? [])
        """)
    } catch {
        print("Error querying role users: \(error)")
    }
}
