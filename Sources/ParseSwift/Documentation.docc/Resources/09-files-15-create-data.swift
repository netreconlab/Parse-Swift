import Foundation
import ParseSwift

// Create some data to upload to Parse
guard let sampleData = "Hello World".data(using: .utf8) else {
    fatalError("Failed to create data from string")
}
print("Created data with \(sampleData.count) bytes")
