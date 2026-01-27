import Foundation
import ParseSwift

// Set the URL for an online file
let linkToFile = URL(string: "https://parseplatform.org/img/logo.svg")!

// Create a new ParseFile for your picture
let profilePic = ParseFile(name: "profile.svg", cloudURL: linkToFile)
print("Created ParseFile: \(profilePic.name)")
