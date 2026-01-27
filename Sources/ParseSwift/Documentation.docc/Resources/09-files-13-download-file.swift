import Foundation
import ParseSwift

Task {
    do {
        // Assume we have a fetched GameScore with a profilePicture
        if let picture = fetchedScore.profilePicture {
            // Download the file content
            let fetchedFile = try await picture.fetch()
            print("File downloaded successfully")
        }
    } catch {
        print("Error downloading file: \(error)")
    }
}
