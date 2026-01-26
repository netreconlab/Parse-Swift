import Foundation
import ParseSwift

var score = GameScore(points: 100)

Task {
    do {
        // Create an ACL with role-based permissions
        var acl = ParseACL()
        
        // Grant read access to users in the "Moderators" role
        acl.setReadAccess(roleName: "Moderators", value: true)
        
        // Grant write access to users in the "Admins" role
        acl.setWriteAccess(roleName: "Admins", value: true)
        
        // Deny public access
        acl.publicRead = false
        acl.publicWrite = false
        
        score.ACL = acl
        let savedScore = try await score.save()
        
        print("Saved score with role-based permissions")
        print("Moderators can read: \(savedScore.ACL?.getReadAccess(roleName: "Moderators") ?? false)")
        print("Admins can write: \(savedScore.ACL?.getWriteAccess(roleName: "Admins") ?? false)")
    } catch {
        print("Error: \(error)")
    }
}
