import Foundation
import ParseSwift

// Create an author with all unsaved book pointers
let newBook = Book(title: "world")
let otherBook1 = Book(title: "I like this book")
let otherBook2 = Book(title: "I like this book also")

var author = Author(name: "Scott", book: newBook)
author.otherBooks = [otherBook1, otherBook2]

do {
    // Batch save with all unsaved pointers
    let results = try await [author].saveAll()
    
    for result in results {
        switch result {
        case .success(let savedAuthor):
            print("Saved author: \(savedAuthor)")
            print("All books were automatically saved")
        case .failure(let error):
            print("Error in batch: \(error)")
        }
    }
} catch {
    print("Error saving all: \(error)")
}
