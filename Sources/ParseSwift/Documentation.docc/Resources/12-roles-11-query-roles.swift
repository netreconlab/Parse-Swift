import Foundation
import ParseSwift

Task {
    do {
        // Use the queryRoles() helper method to find nested roles
        let relatedRoles = try await savedRole!.queryRoles().find()
        
        print("""
            The following roles are part of the
            \"\(String(describing: savedRole!.name))\" role: \(relatedRoles)
        """)
    } catch {
        print("Error querying nested roles: \(error)")
    }
}
