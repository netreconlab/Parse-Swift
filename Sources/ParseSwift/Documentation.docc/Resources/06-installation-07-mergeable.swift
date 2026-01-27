import Foundation
import ParseSwift

// Update installation using mergeable to send only changed fields
Task {
    do {
        var installationToUpdate = try await Installation.current()
        
        // Using .mergeable allows you to send only updated keys
        // to the Parse server instead of the whole object
        installationToUpdate = installationToUpdate.mergeable
        installationToUpdate.customKey = "myCustomInstallationKey2"
        installationToUpdate.channels = ["newDevices"]
        
        let updatedInstallation = try await installationToUpdate.save()
        print("Successfully updated installation: \(updatedInstallation)")
    } catch {
        print("Error updating installation: \(error)")
    }
}
