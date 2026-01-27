import Foundation
import ParseSwift
import Combine

// Configuration manager with notification support
class ConfigManager: ObservableObject {
    @Published var config: Config
    
    init() {
        // Initialize with default config
        self.config = Config()
        
        // Attempt to load cached config
        Task {
            do {
                self.config = try await Config.current()
            } catch {
                print("No cached config available")
            }
        }
    }
    
    // Fetch and update configuration
    func refreshConfiguration() async throws {
        let freshConfig = try await config.fetch()
        
        // Update the published property (notifies observers)
        await MainActor.run {
            self.config = freshConfig
        }
        
        print("Configuration refreshed successfully")
    }
}

struct Config: ParseConfig {
    var welcomeMessage: String? = "Welcome!"
    var winningNumber: Int? = 42
    var newFeatureEnabled: Bool? = false
}

// Usage in SwiftUI or with Combine
let configManager = ConfigManager()

// The @Published property automatically notifies observers when config changes
Task {
    try await configManager.refreshConfiguration()
    // UI automatically updates when config changes
}
