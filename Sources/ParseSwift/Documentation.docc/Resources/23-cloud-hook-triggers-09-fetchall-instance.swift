import Foundation
import ParseSwift

// Fetch all triggers using instance method
// Using myTrigger instance from previous steps
Task {
    do {
        let allTriggers = try await myTrigger.fetchAll()
        print("Found \(allTriggers.count) triggers")
        for trigger in allTriggers {
            print("Trigger: \(trigger.className) - \(trigger.trigger)")
        }
    } catch {
        print("Could not fetch triggers: \(error)")
    }
}
