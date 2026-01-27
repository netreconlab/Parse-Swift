import Foundation
import ParseSwift

// Define a Book model with a pointer to another Book
struct Book: ParseObject, ParseQueryScorable {
    // Required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var score: Double?
    var originalData: Data?

    // Custom properties
    var title: String?
    var relatedBook: Pointer<Book>?
}
