import Foundation
import ParseSwift

// Query for authors without including pointer data
let query = Author.query("name" == "Bruce")

do {
    let author = try await query.first()
    print("Found author: \(author)")
    
    // The book and otherBooks fields contain only objectId references
    // These are called Pointers in Parse
} catch {
    print("Error querying: \(error)")
}
