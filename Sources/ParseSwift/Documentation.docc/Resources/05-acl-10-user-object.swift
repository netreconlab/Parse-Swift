import Foundation
import ParseSwift

var score = GameScore(points: 100)

Task {
    do {
        // Get the current user
        let currentUser = try await User.current()
        
        // Create an ACL using the user object directly
        var acl = ParseACL()
        
        // Grant permissions using the ParseUser object
        acl.setReadAccess(user: currentUser, value: true)
        acl.setWriteAccess(user: currentUser, value: true)
        
        acl.publicRead = false
        acl.publicWrite = false
        
        score.ACL = acl
        let savedScore = try await score.save()
        
        print("Saved score with user object permissions")
        print("User has read access: \(savedScore.ACL?.getReadAccess(user: currentUser) ?? false)")
        print("User has write access: \(savedScore.ACL?.getWriteAccess(user: currentUser) ?? false)")
    } catch {
        print("Error: \(error)")
    }
}
