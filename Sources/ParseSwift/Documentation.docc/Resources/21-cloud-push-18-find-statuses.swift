import Foundation
import ParseSwift

// SERVER-SIDE: Query push notification statuses using primary key
// WARNING: This requires the primary key and must run in a trusted server environment
// Do NOT run this in your client app - use Cloud Code or Parse-Server-Swift/Vapor

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
