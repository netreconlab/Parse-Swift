import Foundation
import ParseSwift

let query = ParsePushStatus<ParsePushPayloadAny>
    .query(isNotNull(key: "objectId"))

// Query statuses with the primary key option
Task {
    do {
        let pushStatuses = try await query.findAll(options: [.usePrimaryKey])
        print("All matching statuses: \"\(pushStatuses)\"")
    } catch {
        print("Could not perform query: \(error)")
    }
}
