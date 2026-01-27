import Foundation
import ParseSwift

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

    // Custom merge method for optimal performance
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

// Custom initializers in an extension
extension Book {
    init(title: String) {
        self.title = title
    }
}
