import Foundation
import ParseSwift

Task {
    do {
        // Save the GameScore to upload the data file
        let savedScore = try await score2.save()
        
        // Fetch to get the updated file metadata
        let fetchedScore = try await savedScore.fetch()
        print("Fetched GameScore with updated file information")
    } catch {
        print("Error: \(error)")
    }
}
