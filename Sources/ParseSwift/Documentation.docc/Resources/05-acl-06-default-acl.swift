import Foundation
import ParseSwift

Task {
    do {
        // Create a default ACL for all new ParseObjects
        var defaultACL = ParseACL()
        defaultACL.publicRead = true
        defaultACL.publicWrite = false
        
        // Set as default ACL with access for current user
        // The current user will automatically get read and write access
        let savedACL = try await ParseACL.setDefaultACL(
            defaultACL,
            withAccessForCurrentUser: true
        )
        
        print("Default ACL set successfully")
        print("Public read: \(savedACL.publicRead)")
        print("Public write: \(savedACL.publicWrite)")
    } catch {
        print("Error setting default ACL: \(error)")
    }
}
