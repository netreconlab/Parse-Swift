import Foundation
import ParseSwift

// Search for books using text matching
do {
    let query = try Book.query(matchesText(key: "title",
                                           text: "like",
                                           options: [:]))
        .include(["*"])
        .sortByTextScore()
    
    let books = try await query.find()
    print("Found \(books.count) books matching 'like'")
    
    for book in books {
        print("Book: \(book.title ?? "no title"), Score: \(book.score ?? 0)")
    }
} catch {
    print("Error searching: \(error)")
}
