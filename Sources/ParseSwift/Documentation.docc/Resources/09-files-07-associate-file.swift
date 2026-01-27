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
print("GameScore now has a profile picture: \(score.profilePicture!.name)")
