import Foundation
import ParseSwift

Task {
    do {
        // Remove a child role from the parent role
        try await savedRole!.roles?.remove([savedRoleModerator!]).save()
        
        print("Role removed from parent role successfully")
        print("Check the \"roles\" field in your \"Role\" class in Parse Dashboard.")
    } catch {
        print("Error removing role from role: \(error)")
    }
}
