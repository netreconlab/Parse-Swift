import Foundation
import ParseSwift

Task {
    do {
        // Retrieve the current default ACL
        let currentDefaultACL = try await ParseACL.defaultACL()
        
        print("Current default ACL:")
        print("Public read: \(currentDefaultACL.publicRead)")
        print("Public write: \(currentDefaultACL.publicWrite)")
    } catch {
        print("Error getting default ACL: \(error)")
    }
}
