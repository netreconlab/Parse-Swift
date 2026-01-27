import Foundation
import ParseSwift

// Create your own value typed ParseObject
struct GameScore: ParseObject {
    // These are required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?
    
    // Your own properties
    var points: Int? = 0
    var profilePicture: ParseFile?
}
