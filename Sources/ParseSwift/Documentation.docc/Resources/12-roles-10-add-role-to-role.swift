import Foundation
import ParseSwift

Task {
    do {
        // Add a child role to the parent role's roles relation
        try await savedRole!.roles?.add([savedMemberRole!]).save()

        print("Role added to parent role successfully")
        print("Check \"roles\" field in your \"Role\" class in Parse Dashboard.")
    } catch {
        print("Error adding role to role: \(error)")
    }
}
