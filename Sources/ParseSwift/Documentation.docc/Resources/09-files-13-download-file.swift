import Foundation
import ParseSwift

// Set the URL for an online file
let linkToFile = URL(string: "https://parseplatform.org/img/logo.svg")!

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
        
        // Fetch the GameScore to get updated file information
        let fetchedScore = try await savedScore.fetch()
        
        // Download the file content
        if let picture = fetchedScore.profilePicture {
            let fetchedFile = try await picture.fetch()
            print("File downloaded successfully")
        }
    } catch {
        print("Error: \(error)")
    }
}
