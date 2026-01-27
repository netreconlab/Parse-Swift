import Foundation
import ParseSwift

// First, get a saved book to query by
let bookToFind = Book(title: "hello")
let savedBook = try await bookToFind.save()

// Query for authors whose "book" field equals this specific Book object
do {
    let query = try Author.query("book" == savedBook)
        .includeAll()
    
    let author = try await query.first()
    print("Found author by book pointer: \(author)")
} catch {
    print("Error querying: \(error)")
}
