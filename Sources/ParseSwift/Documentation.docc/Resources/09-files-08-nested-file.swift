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
print("Added photo to nested GamePhoto object")
