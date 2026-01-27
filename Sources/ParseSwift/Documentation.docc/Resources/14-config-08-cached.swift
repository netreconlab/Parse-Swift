import Foundation
import ParseSwift

struct Config: ParseConfig {
    var welcomeMessage: String?
    var winningNumber: Int?
}

// Access the cached configuration from Keychain
do {
    let cachedConfig = try await Config.current()
    print("Cached config: \(cachedConfig)")
    print("Cached welcome message: \(cachedConfig.welcomeMessage ?? "None")")
} catch {
    print("No cached config available: \(error)")
}
