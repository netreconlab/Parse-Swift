import Foundation
import ParseSwift

struct Config: ParseConfig {
    var welcomeMessage: String?
    var winningNumber: Int?
}

var config = Config()

do {
    // Fetch the configuration from the server
    let fetchedConfig = try await config.fetch()
    print("Successfully fetched config: \(fetchedConfig)")
} catch {
    // Handle errors like network failures
    print("Error fetching config: \(error)")
}
