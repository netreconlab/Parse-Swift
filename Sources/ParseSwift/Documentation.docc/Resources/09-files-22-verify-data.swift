import Foundation
import ParseSwift

Task {
    do {
        // Save the GameScore to upload the data file
        let savedScore = try await score2.save()
        
        // Fetch to get the updated file metadata
        let fetchedScore = try await savedScore.fetch()
        
        // Download the data file
        if let myData = fetchedScore.myData {
            let fetchedFile = try await myData.fetch()
            
            // Read the file contents from the local URL
            if let localURL = fetchedFile.localURL {
                let dataFromParseFile = try Data(contentsOf: localURL)
                
                // Verify the data matches the original
                if dataFromParseFile == sampleData {
                    print("✓ Data integrity verified - content matches original")
                }
                
                // Convert to string and display
                let parseFileString = String(decoding: dataFromParseFile, as: UTF8.self)
                print("The data saved on Parse Server is: \"\(parseFileString)\"")
            }
        }
    } catch {
        print("Error: \(error)")
    }
}
