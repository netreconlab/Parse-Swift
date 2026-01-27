import Foundation
import ParseSwift

// Create some data to upload to Parse
guard let sampleData = "Hello World".data(using: .utf8) else {
    fatalError("Failed to create data from string")
}

// Create a new ParseFile from the data
let helloFile = ParseFile(name: "hello.txt", data: sampleData)

// Create a new GameScore and assign the data file
var score2 = GameScore(points: 105)
score2.myData = helloFile

Task {
    do {
        // Save the GameScore to upload the data file
        _ = try await score2.save()
        print("Successfully saved GameScore with data file")
        print("The file has been uploaded to Parse Server")
    } catch {
        print("Error saving: \(error)")
    }
}
