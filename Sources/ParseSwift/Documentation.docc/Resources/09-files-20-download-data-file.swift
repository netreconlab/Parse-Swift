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
            print("Downloaded data file to device")
        }
    } catch {
        print("Error: \(error)")
    }
}
