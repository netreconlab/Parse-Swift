import Foundation
import ParseSwift

struct Config: ParseConfig {
    var welcomeMessage: String?
    var winningNumber: Int?
}

// Create a config instance
var config = Config()

Task {
    do {
        // Fetch the current configuration from the server
        let fetchedConfig = try await config.fetch()
        print("Current config: \(fetchedConfig)")
    } catch {
        print("Error fetching config: \(error)")
    }
}
