import Foundation
import ParseSwift

struct Config: ParseConfig {
    var welcomeMessage: String?
    var winningNumber: Int?
}

var config = Config()

Task {
    do {
        // Fetch the current configuration
        config = try await config.fetch()
        
        // Modify a configuration parameter
        config.winningNumber = 50
        print("Updated winning number to 50")
    } catch {
        print("Error fetching config: \(error)")
    }
}
