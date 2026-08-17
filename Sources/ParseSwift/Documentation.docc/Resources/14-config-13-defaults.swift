import Foundation
import ParseSwift

// Provide default values for all configuration parameters
struct Config: ParseConfig {
    // Always provide sensible defaults
    var welcomeMessage: String? = "Welcome to our app!"
    var winningNumber: Int? = 42
    var newFeatureEnabled: Bool? = false
    var promotionalMessage: String?
    var maxRetries: Int? = 3
    var timeoutSeconds: Int? = 30
}

// The defaults ensure the app works even if server config is unavailable
var config = Config()
print("Default welcome message: \(config.welcomeMessage ?? "None")")
print("Default winning number: \(config.winningNumber ?? 0)")
