import Foundation
import ParseSwift

struct Config: ParseConfig {
    var welcomeMessage: String? = "Welcome!"
    var winningNumber: Int? = 42
}

// Fetch configuration when app launches
func initializeApp() async {
    var config = Config()
    
    do {
        // Try to fetch the latest configuration
        config = try await config.fetch()
        print("Successfully loaded latest configuration")
    } catch {
        print("Failed to fetch config, using cached or defaults: \(error)")
        
        // Try to use cached configuration
        do {
            config = try await Config.current()
            print("Using cached configuration")
        } catch {
            print("No cached config, using defaults")
        }
    }
    
    // Continue with app initialization using the config
    print("App initialized with config: \(config)")
}

// Call during app launch
Task {
    await initializeApp()
}
