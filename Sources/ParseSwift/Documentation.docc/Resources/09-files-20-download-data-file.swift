import Foundation
import ParseSwift

// Create some data to upload to Parse
let sampleData = "Hello World".data(using: .utf8)!

// Create a new ParseFile from the data
let helloFile = ParseFile(name: "hello.txt", data: sampleData)

// Create a new GameScore and assign the data file
var score2 = GameScore(points: 105)
score2.myData = helloFile

Task {
    do {
        // Save the GameScore to upload the data file
        let savedScore = try await score2.save()
        
        // Fetch to get the updated file metadata
        let fetchedScore = try await savedScore.fetch()
        
        // Download the data file
        if let myData = fetchedScore.myData {
            let fetchedFile = try await myData.fetch()
            print("Downloaded data file to device")
        }
    } catch {
        print("Error: \(error)")
    }
}
