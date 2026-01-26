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

Task {
    do {
        // First, save a score with an ACL
        var score = GameScore(points: 100)
        var acl = ParseACL()
        acl.publicRead = true
        acl.publicWrite = false
        score.ACL = acl
        
        let savedScore = try await score.save()
        print("Initial ACL - Public read: \(savedScore.ACL?.publicRead ?? false)")
        
        // Modify the ACL on the existing object
        var updatedScore = savedScore.mergeable
        var modifiedACL = savedScore.ACL ?? ParseACL()
        
        // Change the permissions
        modifiedACL.publicRead = false
        modifiedACL.publicWrite = false
        
        updatedScore.ACL = modifiedACL
        
        // Save the updated ACL
        let finalScore = try await updatedScore.save()
        print("Updated ACL - Public read: \(finalScore.ACL?.publicRead ?? false)")
    } catch {
        print("Error: \(error)")
    }
}
