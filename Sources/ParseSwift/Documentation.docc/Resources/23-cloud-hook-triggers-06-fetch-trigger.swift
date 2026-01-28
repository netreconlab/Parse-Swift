import Foundation
import ParseSwift

// Fetch a trigger from Parse Server
// Using myTrigger from previous steps
Task {
    do {
        let fetchedTrigger = try await myTrigger.fetch()
        print("Fetched trigger: \(fetchedTrigger)")
        print("Trigger URL: \(fetchedTrigger.url)")
        print("Trigger type: \(fetchedTrigger.trigger)")
    } catch {
        print("Could not fetch trigger: \(error)")
    }
}
