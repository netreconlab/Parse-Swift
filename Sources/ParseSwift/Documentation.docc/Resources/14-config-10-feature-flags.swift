import Foundation
import ParseSwift

// Use configuration for feature flags
struct Config: ParseConfig {
    var welcomeMessage: String?
    var winningNumber: Int?
    
    // Feature flags
    var newFeatureEnabled: Bool?
    var experimentalUIEnabled: Bool?
    var debugModeEnabled: Bool?
}

var config = Config()

do {
    config = try await config.fetch()
    
    // Check feature flags to enable/disable features
    if config.newFeatureEnabled == true {
        print("Enabling new feature")
        // Enable the feature in your app
    }
    
    if config.experimentalUIEnabled == true {
        print("Showing experimental UI")
        // Show the new UI
    }
} catch {
    print("Error: \(error)")
}
