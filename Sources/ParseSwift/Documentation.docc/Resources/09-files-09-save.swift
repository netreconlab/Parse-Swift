import Foundation
import ParseSwift

Task {
    do {
        // Save the GameScore with the associated file
        let savedScore = try await score.save()
        print("Successfully saved GameScore with profile picture")
    } catch {
        print("Error saving: \(error)")
    }
}
