import Foundation
import ParseSwift

Task {
    do {
        // Save the GameScore with the associated file
        let savedScore = try await score.save()
        
        // Fetch the GameScore to get updated file information
        let fetchedScore = try await savedScore.fetch()
        
        // Download the file content
        if let picture = fetchedScore.profilePicture {
            let fetchedFile = try await picture.fetch()
            print("File downloaded successfully")
        }
    } catch {
        print("Error: \(error)")
    }
}
