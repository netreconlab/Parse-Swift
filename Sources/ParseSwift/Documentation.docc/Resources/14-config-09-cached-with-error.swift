import Foundation
import ParseSwift

struct Config: ParseConfig {
    var welcomeMessage: String?
    var winningNumber: Int?
}

Task {
    do {
        // Try to get the cached configuration
        let cachedConfig = try await Config.current()
        print("Using cached config: \(cachedConfig)")
    } catch {
        // Handle the case where no config has been cached yet
        print("No cached configuration found. Fetching from server...")

        do {
            var config = Config()
            let fetchedConfig = try await config.fetch()
            print("Fetched fresh config: \(fetchedConfig)")
        } catch {
            print("Error fetching config: \(error)")
        }
    }
}
