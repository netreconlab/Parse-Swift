import Foundation
import ParseSwift

// Subscribe to push notification channels
Task {
    do {
        var currentInstallation = try await Installation.current()
        
        // Subscribe to specific channels
        currentInstallation.channels = ["news", "sports", "updates"]
        
        let savedInstallation = try await currentInstallation.save()
        print("Successfully subscribed to channels: \(savedInstallation.channels ?? [])")
    } catch {
        print("Error updating channels: \(error)")
    }
}
