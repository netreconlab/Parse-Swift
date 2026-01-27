import Foundation
import ParseSwift

Task {
    do {
        // Save the GameScore to upload the data file
        let savedScore = try await score2.save()
        print("Successfully saved GameScore with data file")
        print("The file has been uploaded to Parse Server")
    } catch {
        print("Error saving: \(error)")
    }
}
