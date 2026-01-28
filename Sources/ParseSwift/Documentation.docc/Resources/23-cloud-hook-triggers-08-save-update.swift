import Foundation
import ParseSwift

// Save the updated trigger to Parse Server
// Using modified myTrigger from previous step
Task {
    do {
        let updatedTrigger = try await myTrigger.update()
        print("Updated trigger successfully!")
        print("New URL: \(updatedTrigger.url)")
    } catch {
        print("Could not update trigger: \(error)")
    }
}
