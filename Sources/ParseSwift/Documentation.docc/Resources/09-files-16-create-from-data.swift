import Foundation
import ParseSwift

// Create some data to upload to Parse
guard let sampleData = "Hello World".data(using: .utf8) else {
    fatalError("Failed to create data from string")
}

// Create a new ParseFile from the data
let helloFile = ParseFile(name: "hello.txt", data: sampleData)
print("Created ParseFile from data: \(helloFile.name)")
