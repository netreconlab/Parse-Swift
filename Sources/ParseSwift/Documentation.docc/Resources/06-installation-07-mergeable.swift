import Foundation
import ParseSwift

// Update installation using mergeable to send only changed fields
Task {
    do {
        var installationToUpdate = try await Installation.current()

        // Ensure the installation has been saved at least once
        if !(try await installationToUpdate.isSaved()) {
            installationToUpdate = try await installationToUpdate.save()
        }

        // Using `.mergeable` on an already-saved installation allows you to send
        // only the keys you modify to Parse Server instead of the whole object
        installationToUpdate = installationToUpdate.mergeable
        installationToUpdate.customKey = "myCustomInstallationKey2"
        installationToUpdate.channels = ["newDevices"]

        let updatedInstallation = try await installationToUpdate.save()
        print("Successfully updated installation: \(updatedInstallation)")
    } catch {
        print("Error updating installation: \(error)")
    }
}
