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
            
            // Access the downloaded file from its local URL
            if let localURL = fetchedFile.localURL {
                print("File is now saved on your device at: \(localURL)")
                print("You can now load the file data, display an image, etc.")
            }
        }
    } catch {
        print("Error: \(error)")
    }
}
