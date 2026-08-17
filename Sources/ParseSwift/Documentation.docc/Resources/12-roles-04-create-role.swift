import Foundation
import ParseSwift

Task {
    do {
        // Get the current user
        let currentUser = try await User.current()

        // Every role requires an ACL that cannot be changed after saving
        var acl = ParseACL()
        acl.setReadAccess(user: currentUser, value: true)
        acl.setWriteAccess(user: currentUser, value: true)

        // Create the actual role with a name and ACL
        var adminRole = try Role<User>(name: "Administrator", acl: acl)
        adminRole.subtitle = "staff"

        print("Role created with name: \(adminRole.name ?? "")")
    } catch {
        print("Error creating role: \(error)")
    }
}
