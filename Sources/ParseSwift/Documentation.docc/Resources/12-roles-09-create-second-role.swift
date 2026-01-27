import Foundation
import ParseSwift

// Variable to store the second role
var savedRoleModerator: Role<User>?

Task {
    do {
        // Get the current user
        let currentUser = try await User.current()
        
        // Create ACL for the new role
        var acl = ParseACL()
        acl.setReadAccess(user: currentUser, value: true)
        acl.setWriteAccess(user: currentUser, value: true)
        
        // Create the Member role
        let memberRole = try Role<User>(name: "Member", acl: acl)
        
        // Save the role
        savedRoleModerator = try await memberRole.save()
        
        print("The role saved successfully: \(savedRoleModerator!)")
        print("Check your \"Role\" class in Parse Dashboard.")
    } catch {
        print("Error creating second role: \(error)")
    }
}
