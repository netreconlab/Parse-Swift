import Foundation
import ParseSwift

// Create some data to upload to Parse
let sampleData = "Hello World".data(using: .utf8)!

// Create a new ParseFile from the data
let helloFile = ParseFile(name: "hello.txt", data: sampleData)

// Create a new GameScore and assign the data file
var score2 = GameScore(points: 105)
score2.myData = helloFile
print("Assigned data file to GameScore")
