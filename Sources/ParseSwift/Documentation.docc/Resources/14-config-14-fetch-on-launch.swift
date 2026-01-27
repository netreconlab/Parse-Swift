import Foundation
import ParseSwift

struct Config: ParseConfig {
    var welcomeMessage: String? = "Welcome!"
    var winningNumber: Int? = 42
}

// Fetch configuration early in your app lifecycle
var config = Config()

Task {
    do {
        // Try to fetch the latest configuration
        config = try await config.fetch()
        print("Successfully loaded latest configuration")
    } catch {
        print("Failed to fetch config, using cached or defaults: \(error)")
        
        // Try to use cached configuration as fallback
        do {
            config = try await Config.current()
            print("Using cached configuration")
        } catch {
            print("No cached config, using defaults")
        }
    }
}

