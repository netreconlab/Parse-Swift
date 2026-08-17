import Foundation
import ParseSwift

struct Book: ParseObject, ParseQueryScorable {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var score: Double?
    var originalData: Data?
    var title: String?
    var relatedBook: Pointer<Book>?

    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.title, original: object) {
            updated.title = object.title
        }
        if updated.shouldRestoreKey(\.relatedBook, original: object) {
            updated.relatedBook = object.relatedBook
        }
        return updated
    }
}

extension Book {
    init(title: String) {
        self.title = title
    }
}

// Define an Author model with pointers to Book objects
struct Author: ParseObject {
    // Required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    // Custom properties with pointers
    var name: String?
    var book: Book?           // Single pointer to a Book
    var otherBooks: [Book]?   // Array of pointers to Books
}
