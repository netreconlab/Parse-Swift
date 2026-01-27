import Foundation
import ParseSwift

Task {
    do {
        // Create an ACL with role-based permissions
        var acl = ParseACL()
        acl.setReadAccess(roleName: "Administrator", value: true)
        acl.setWriteAccess(roleName: "Administrator", value: true)

        // Create and save an object with the role-based ACL
        var gameScore = GameScore(points: 100)
        gameScore.ACL = acl

        let savedScore = try await gameScore.save()

        print("Object saved with role-based ACL: \(savedScore)")
        print("Only users in the Administrator role can access this object")
        print("Check the ACL field in Parse Dashboard")
    } catch {
        print("Error saving object with role-based ACL: \(error)")
    }
}
