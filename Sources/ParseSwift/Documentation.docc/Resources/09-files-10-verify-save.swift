import Foundation
import ParseSwift

// Set the URL for an online file
guard let linkToFile = URL(string: "https://parseplatform.org/img/logo.svg") else {
    fatalError("Invalid URL")
}

// Create a new ParseFile for your picture
let profilePic = ParseFile(name: "profile.svg", cloudURL: linkToFile)

// Define initial GameScore
var score = GameScore(points: 52)

// Associate the ParseFile with your ParseObject
score.profilePicture = profilePic

// Set the picture in a nested ParseObject
var photo = GamePhoto()
photo.image = profilePic
score.otherPhoto = photo

Task {
    do {
        // Save the GameScore with the associated file
        let savedScore = try await score.save()
        
        // Verify the saved object has expected properties
        if let objectId = savedScore.objectId {
            print("✓ Object saved with ID: \(objectId)")
        }
        if let createdAt = savedScore.createdAt {
            print("✓ Created at: \(createdAt)")
        }
        if savedScore.profilePicture != nil {
            print("✓ Profile picture is associated with the object")
        }
        print("Points: \(savedScore.points ?? 0)")
    } catch {
        print("Error saving: \(error)")
    }
}
