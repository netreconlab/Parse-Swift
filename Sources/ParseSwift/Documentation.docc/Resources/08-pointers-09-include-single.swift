import Foundation
import ParseSwift

// Include the "book" field to fetch the complete Book object
let query = Author.query("name" == "Bruce")
    .include("book")

do {
    let author = try await query.first()
    print("Found author with included book: \(author)")
    
    // Now the book field contains the complete Book object, not just the objectId
    if let book = author.book {
        print("Book title: \(book.title ?? "no title")")
    }
} catch {
    print("Error querying: \(error)")
}
