import Foundation
import ParseSwift

Task {
    do {
        // Save the GameScore with the associated file
        let savedScore = try await score.save()
        
        // Verify the saved object has expected properties
        if savedScore.objectId != nil {
            print("✓ Object saved with ID: \(savedScore.objectId!)")
        }
        if savedScore.createdAt != nil {
            print("✓ Created at: \(savedScore.createdAt!)")
        }
        if savedScore.profilePicture != nil {
            print("✓ Profile picture is associated with the object")
        }
        print("Points: \(savedScore.points ?? 0)")
    } catch {
        print("Error saving: \(error)")
    }
}
