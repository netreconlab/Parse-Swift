import Foundation
import ParseSwift

// Make trigger setup idempotent for reliable deployment
func ensureTrigger(for object: some ParseObject,
                   trigger: ParseHookTriggerType,
                   url: URL) async throws -> ParseHookTrigger {

    // Try to fetch existing triggers
    let allTriggers = try await ParseHookTrigger.fetchAll()

    // Find matching trigger
    if let existing = allTriggers.first(where: {
        $0.className == object.className &&
        $0.trigger == trigger
    }) {
        // Update if URL changed
        if existing.url != url {
            var updated = existing
            updated.url = url
            return try await updated.update()
        }
        return existing
    } else {
        // Create new trigger
        let newTrigger = ParseHookTrigger(object: object,
                                          trigger: trigger,
                                          url: url)
        return try await newTrigger.create()
    }
}
