import Foundation
import ParseSwift

// A ParseObject that primarily contains an image file
struct GamePhoto: ParseObject {
    // These are required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?
    
    // Your own properties
    var image: ParseFile?
}
