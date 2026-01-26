import Foundation
import ParseSwift

var score = GameScore(points: 100)

Task {
    do {
        // Create an ACL with specific public permissions
        var acl = ParseACL()
        
        // Allow anyone to read this object
        acl.publicRead = true
        
        // Don't allow anyone to write this object
        acl.publicWrite = false
        
        // Assign the ACL to the object
        score.ACL = acl
        
        // Save the object with the ACL
        let savedScore = try await score.save()
        
        print("Saved score with public read only")
        print("Public can read: \(savedScore.ACL?.publicRead ?? false)")
        print("Public can write: \(savedScore.ACL?.publicWrite ?? false)")
    } catch {
        print("Error saving: \(error)")
    }
}
