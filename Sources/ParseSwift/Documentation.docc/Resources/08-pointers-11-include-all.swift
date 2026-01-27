import Foundation
import ParseSwift

// Include all pointer fields using includeAll()
let query = Author.query("name" == "Bruce")
    .includeAll()

do {
    let author = try await query.first()
    print("Found author with all pointers included: \(author)")
    
    // All pointer fields (book and otherBooks) contain complete objects
} catch {
    print("Error querying: \(error)")
}

// Alternative: use include("*") for the same result
let queryAlt = Author.query("name" == "Bruce")
    .include("*")
