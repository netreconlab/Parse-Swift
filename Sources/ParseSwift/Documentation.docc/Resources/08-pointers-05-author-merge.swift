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

struct Author: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?
    var name: String?
    var book: Book?
    var otherBooks: [Book]?
    
    // Custom merge method for optimal performance
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.name, original: object) {
            updated.name = object.name
        }
        if updated.shouldRestoreKey(\.book, original: object) {
            updated.book = object.book
        }
        if updated.shouldRestoreKey(\.otherBooks, original: object) {
            updated.otherBooks = object.otherBooks
        }
        return updated
    }
}

extension Author {
    init(name: String, book: Book) {
        self.name = name
        self.book = book
    }
}
