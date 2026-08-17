import Foundation
import ParseSwift

// Fetch all triggers using type method
Task {
    do {
        let allTriggers = try await ParseHookTrigger.fetchAll()
        print("Total triggers on server: \(allTriggers.count)")
        for trigger in allTriggers {
            print("Class: \(trigger.className), Trigger: \(trigger.trigger)")
            print("URL: \(trigger.url)")
        }
    } catch {
        print("Could not fetch triggers: \(error)")
    }
}
