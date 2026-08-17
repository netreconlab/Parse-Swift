import Foundation
import ParseSwift

// Create a query for push statuses
// Use ParsePushPayloadAny for mixed push environments
let query = ParsePushStatus<ParsePushPayloadAny>
    .query(isNotNull(key: "objectId"))
