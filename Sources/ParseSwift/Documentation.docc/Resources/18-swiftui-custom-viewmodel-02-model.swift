import Foundation
import ParseSwift
import SwiftUI
import Combine

// Create your own value typed ParseObject
struct GameScore: ParseObject {

    // These are required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    // Your own properties
    var points: Int?
    var location: ParseGeoPoint?
    var name: String?
}
