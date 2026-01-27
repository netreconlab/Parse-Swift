import Foundation
import ParseSwift

// Include multiple pointer fields
let query = Author.query("name" == "Bruce")
    .include(["book", "otherBooks"])

do {
    let author = try await query.first()
    print("Found author with included book and otherBooks: \(author)")

    // Both book and otherBooks contain complete objects
} catch {
    print("Error querying: \(error)")
}
