import Foundation
import ParseSwift

struct GameScore: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?
    var points: Int?
    
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.points, original: object) {
            updated.points = object.points
        }
        return updated
    }
}

extension GameScore {
    init(points: Int) {
        self.points = points
    }
}

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
