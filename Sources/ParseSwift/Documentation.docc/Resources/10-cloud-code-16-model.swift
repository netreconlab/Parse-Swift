import Foundation
import ParseSwift

// Define a ParseObject model
struct GameScore: ParseObject {
    // Required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?
    
    // Custom properties
    var points: Int?
}
