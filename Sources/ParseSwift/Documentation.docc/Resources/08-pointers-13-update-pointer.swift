import Foundation
import ParseSwift

// First, query for the author with included book data
let query = try Author.query("name" == "Bruce")
    .include("book")

let author = try await query.first()

if let authorBook = author.book,
   let firstOtherBook = author.otherBooks?.first {
    
    // Create a mutable copy and update the relatedBook pointer
    var modifiedBook = authorBook.mergeable
    modifiedBook.relatedBook = try? firstOtherBook.toPointer()
    
    do {
        let updatedBook = try await modifiedBook.save()
        print("Updated book with related book pointer: \(updatedBook)")
    } catch {
        print("Error updating: \(error)")
    }
}
