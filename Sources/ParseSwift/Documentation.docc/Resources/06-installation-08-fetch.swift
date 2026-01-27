import Foundation
import ParseSwift

// Fetch the current installation from Parse Server
Task {
    do {
        let currentInstallation = try await Installation.current()
        let fetchedInstallation = try await currentInstallation.fetch()

        print("Successfully fetched installation: \(fetchedInstallation)")
        print("Installation ID: \(fetchedInstallation.installationId ?? "none")")
        print("Custom key: \(fetchedInstallation.customKey ?? "none")")
    } catch {
        print("Error fetching installation: \(error)")
    }
}
