import Foundation
import ParseSwift

Task {
    do {
        // Save the GameScore with the associated file
        let savedScore = try await score.save()
        
        // Fetch the GameScore to get updated file information
        let fetchedScore = try await savedScore.fetch()
        
        // Access the file metadata
        if let picture = fetchedScore.profilePicture,
           let url = picture.url {
            print("File name: \(picture.name)")
            print("File URL on Parse Server: \(url)")
            print("Full ParseFile details: \(picture)")
        }
    } catch {
        print("Error: \(error)")
    }
}
