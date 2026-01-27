import Foundation
import ParseSwift

Task {
    do {
        // Save the GameScore with the associated file
        let savedScore = try await score.save()
        
        // Fetch the GameScore to get updated file information
        let fetchedScore = try await savedScore.fetch()
        print("Fetched GameScore from server")
    } catch {
        print("Error: \(error)")
    }
}
