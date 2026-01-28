import Foundation
import ParseSwift

let query = ParsePushStatus<ParsePushPayloadAny>
    .query(isNotNull(key: "objectId"))

// Query statuses with the primary key option
query.findAll(options: [.usePrimaryKey]) { result in
    switch result {
    case .success(let pushStatuses):
        print("All matching statuses: \"\(pushStatuses)\"")
    case .failure(let error):
        print("Could not perform query: \(error)")
    }
}
