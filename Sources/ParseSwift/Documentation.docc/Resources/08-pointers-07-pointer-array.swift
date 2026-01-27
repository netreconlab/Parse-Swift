import Foundation
import ParseSwift

// Create an Author with multiple book pointers
let newBook = Book(title: "hello")
let otherBook1 = Book(title: "I like this book")
let otherBook2 = Book(title: "I like this book also")

var author = Author(name: "Bruce", book: newBook)
author.otherBooks = [otherBook1, otherBook2]

do {
    // Save the author with multiple book references
    let savedAuthor = try await author.save()
    
    print("Saved author: \(savedAuthor)")
    print("Author has \(savedAuthor.otherBooks?.count ?? 0) books in otherBooks")
    
    // Note: The pointer objects have not been updated on the client
    // To get the latest pointer objects, fetch and include them
} catch {
    print("Error saving: \(error)")
}
