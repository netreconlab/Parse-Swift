import Foundation
import ParseSwift

// Update badge count for the installation
Task {
    do {
        var installationToUpdate = try await Installation.current()
        installationToUpdate = installationToUpdate.mergeable
        
        // Reset badge count to 0
        installationToUpdate.badge = 0
        
        let updatedInstallation = try await installationToUpdate.save()
        print("Successfully updated badge: \(updatedInstallation.badge ?? 0)")
    } catch {
        print("Error updating badge: \(error)")
    }
}
