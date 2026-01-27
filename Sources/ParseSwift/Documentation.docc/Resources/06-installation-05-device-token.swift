import Foundation
import ParseSwift

// Set device token for push notifications
func registerDeviceToken(_ deviceTokenData: Data) {
    Task {
        do {
            var currentInstallation = try await Installation.current()
            
            // In a real app, you would get this Data from APNS registration
            currentInstallation.setDeviceToken(deviceTokenData)
            currentInstallation.badge = 0
            
            let savedInstallation = try await currentInstallation.save()
            print("Successfully saved installation with device token: \(savedInstallation)")
        } catch {
            print("Error saving installation: \(error)")
        }
    }
}

// Example usage for this tutorial step:
// In a real app, `deviceTokenData` comes from APNS registration callbacks.
let sampleDeviceToken = Data(repeating: 0, count: 32) // Placeholder token for demonstration
registerDeviceToken(sampleDeviceToken)
