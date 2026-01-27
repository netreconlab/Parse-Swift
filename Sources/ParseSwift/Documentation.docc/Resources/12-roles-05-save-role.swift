import Foundation
import ParseSwift

// Variable to store the saved role
var savedRole: Role<User>?

Task {
    do {
        // Get the current user
        let currentUser = try await User.current()

        // Create role with ACL
        var acl = ParseACL()
        acl.setReadAccess(user: currentUser, value: true)
        acl.setWriteAccess(user: currentUser, value: true)

        var adminRole = try Role<User>(name: "Administrator", acl: acl)
        adminRole.subtitle = "staff"

        // Save the role using async/await
        savedRole = try await adminRole.save()

        print("The role saved successfully: \(savedRole!)")
        print("Check your \"Role\" class in Parse Dashboard.")
    } catch {
        print("Error saving role: \(error)")
    }
}
