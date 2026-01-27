import Foundation
import ParseSwift

// Get the current installation
do {
    let currentInstallation = try await Installation.current()
    print("Current installation: \(currentInstallation)")
} catch {
    print("Error getting current installation: \(error)")
}
