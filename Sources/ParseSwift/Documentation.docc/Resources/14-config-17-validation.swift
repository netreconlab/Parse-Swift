import Foundation
import ParseSwift

struct Config: ParseConfig {
    var welcomeMessage: String? = "Welcome!"
    var winningNumber: Int? = 42
    var maxUploadSizeMB: Int? = 10
    var apiEndpoint: String? = "https://api.example.com"
}

extension Config {
    // Validate configuration values
    func validate() throws {
        // Ensure winning number is in valid range
        if let number = winningNumber, number < 1 || number > 100 {
            throw NSError(domain: "ConfigError", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "Winning number must be between 1 and 100"])
        }
        
        // Ensure max upload size is reasonable
        if let size = maxUploadSizeMB, size < 1 || size > 100 {
            throw NSError(domain: "ConfigError", code: 2,
                         userInfo: [NSLocalizedDescriptionKey: "Max upload size must be between 1 and 100 MB"])
        }
        
        // Validate API endpoint format
        if let endpoint = apiEndpoint, !endpoint.hasPrefix("https://") {
            throw NSError(domain: "ConfigError", code: 3,
                         userInfo: [NSLocalizedDescriptionKey: "API endpoint must use HTTPS"])
        }
    }
}

// Fetch and validate configuration
var config = Config()

do {
    config = try await config.fetch()
    try config.validate()
    print("Configuration is valid: \(config)")
} catch {
    print("Configuration validation failed: \(error)")
}
