import Foundation
import ParseSwift

// Delete a trigger from Parse Server
// Using myTrigger from previous steps
Task {
    do {
        try await myTrigger.delete()
        print("Trigger deleted successfully!")
    } catch {
        print("Could not delete trigger: \(error)")
    }
}
