import Foundation
import ParseSwift

// Monitor and audit trigger configurations
func auditTriggers() async throws {
    let allTriggers = try await ParseHookTrigger.fetchAll()

    print("=== Trigger Audit Report ===")
    print("Total triggers: \(allTriggers.count)")

    // Group triggers by class
    var triggersByClass: [String: [ParseHookTrigger]] = [:]
    for trigger in allTriggers {
        guard let className = trigger.className else {
            continue
        }
        triggersByClass[className, default: []].append(trigger)
    }

    // Print summary
    for (className, triggers) in triggersByClass.sorted(by: { $0.key < $1.key }) {
        print("\nClass: \(className)")
        for trigger in triggers {
            print("  - \(trigger.trigger): \(trigger.url)")
        }
    }
}
