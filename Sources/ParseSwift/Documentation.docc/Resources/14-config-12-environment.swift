import Foundation
import ParseSwift

// Use configuration for environment-specific settings
struct Config: ParseConfig {
    var welcomeMessage: String?
    var winningNumber: Int?
    
    // Environment configuration
    var apiEndpoint: String?
    var loggingLevel: String?
    var maxRetries: Int?
    var timeoutSeconds: Int?
}

var config = Config()

Task {
    do {
        config = try await config.fetch()
        
        // Use environment-specific settings
        if let endpoint = config.apiEndpoint {
            print("API endpoint: \(endpoint)")
            // Configure network layer
        }
        
        if let level = config.loggingLevel {
            print("Logging level: \(level)")
            // Set logging configuration
        }
        
        if let retries = config.maxRetries {
            print("Max retries: \(retries)")
            // Configure retry logic
        }
    } catch {
        print("Error: \(error)")
    }
}
