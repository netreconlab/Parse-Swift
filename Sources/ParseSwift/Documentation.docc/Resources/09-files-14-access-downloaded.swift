import Foundation
import ParseSwift

Task {
    do {
        // Assume we have a fetched GameScore with a profilePicture
        if let picture = fetchedScore.profilePicture {
            // Download the file content
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
