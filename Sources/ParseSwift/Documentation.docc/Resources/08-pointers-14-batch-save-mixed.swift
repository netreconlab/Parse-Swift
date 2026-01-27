import Foundation
import ParseSwift

let unsavedBook = Book(title: "hello")

let otherBook1 = Book(title: "I like this book")
let otherBook2 = Book(title: "I like this book also")

do {
    // Pre-save one book so it already has an objectId
    let savedBook = try await unsavedBook.save()

    var author = Author(name: "Logan", book: savedBook)
    author.otherBooks = [otherBook1, otherBook2]
    
    // Batch save - Parse handles saving unsaved pointers automatically
    let results = try await [author].saveAll()
    
    for result in results {
        switch result {
        case .success(let savedAuthor):
            print("Saved author: \(savedAuthor)")
            // Note: Pointer objects are not updated on the client
        case .failure(let error):
            print("Error in batch: \(error)")
        }
    }
} catch {
    print("Error saving all: \(error)")
}
