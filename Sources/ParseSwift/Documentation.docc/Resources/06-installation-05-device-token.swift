import Foundation
import ParseSwift

// Set device token for push notifications
Task {
    do {
        var currentInstallation = try await Installation.current()
        
        // In a real app, you would get this from APNS registration
        currentInstallation.deviceToken = "your-device-token-from-apns"
        currentInstallation.badge = 0
        
        let savedInstallation = try await currentInstallation.save()
        print("Successfully saved installation with device token: \(savedInstallation)")
    } catch {
        print("Error saving installation: \(error)")
    }
}
