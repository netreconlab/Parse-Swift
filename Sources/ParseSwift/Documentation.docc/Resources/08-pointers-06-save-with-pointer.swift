import Foundation
import ParseSwift

// Create a Book and an Author that references it
let newBook = Book(title: "hello")
let author = Author(name: "Alice", book: newBook)

do {
    // Save the author - Parse automatically saves the referenced book
    let savedAuthor = try await author.save()
    
    print("Saved author: \(savedAuthor)")
    print("Author has objectId: \(savedAuthor.objectId ?? "none")")
    print("Book was automatically saved with author")
} catch {
    print("Error saving: \(error)")
}
