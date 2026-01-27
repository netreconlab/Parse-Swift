import Foundation
import ParseSwift

// Save the current installation to Parse Server
Task {
    do {
        var currentInstallation = try await Installation.current()
        currentInstallation.customKey = "myCustomInstallationKey"
        
        let savedInstallation = try await currentInstallation.save()
        print("Successfully saved installation: \(savedInstallation)")
    } catch {
        print("Error saving installation: \(error)")
    }
}
