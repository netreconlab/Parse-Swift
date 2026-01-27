import Foundation
import ParseSwift

// Define type-safe configuration access
struct Config: ParseConfig {
    var welcomeMessage: String? = "Welcome!"
    var winningNumber: Int? = 42
    var newFeatureEnabled: Bool? = false
    var minAppVersion: String? = "1.0.0"
}

extension Config {
    // Computed properties for type-safe access with guaranteed defaults
    var safeWelcomeMessage: String {
        return welcomeMessage ?? "Welcome to our app!"
    }
    
    var safeWinningNumber: Int {
        return winningNumber ?? 42
    }
    
    var isNewFeatureEnabled: Bool {
        return newFeatureEnabled ?? false
    }
    
    // Validation methods
    func isVersionSupported(_ currentVersion: String) -> Bool {
        guard let minVersion = minAppVersion else { return true }
        // Note: This uses a simple numeric string comparison. For production use,
        // consider using a proper semantic versioning library
        return currentVersion.compare(minVersion, options: .numeric) != .orderedAscending
    }
}

// Usage with type safety
var config = Config()
print(config.safeWelcomeMessage) // Always returns a String
print(config.isNewFeatureEnabled) // Always returns a Bool
