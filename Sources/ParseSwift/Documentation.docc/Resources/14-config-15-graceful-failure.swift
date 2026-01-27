import Foundation
import ParseSwift

struct Config: ParseConfig {
    var welcomeMessage: String? = "Welcome!"
    var winningNumber: Int? = 42
    var newFeatureEnabled: Bool? = false
}

// Handle fetch failures gracefully with fallback strategy
func getConfiguration() async -> Config {
    var config = Config()
    
    do {
        // Try to fetch from server
        return try await config.fetch()
    } catch {
        print("Server fetch failed: \(error)")
        
        // Try cached version
        do {
            return try await Config.current()
        } catch {
            print("No cached config: \(error)")
            
            // Return default configuration
            print("Using default configuration")
            return config
        }
    }
}

// Use the configuration
Task {
    let config = await getConfiguration()
    print("Using configuration: \(config)")
}
