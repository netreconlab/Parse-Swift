import Foundation
import ParseSwift

struct Config: ParseConfig {
    var welcomeMessage: String?
    var winningNumber: Int?
}

var config = Config()

do {
    config = try await config.fetch()
    config.winningNumber = 50
    let isUpdated = try await config.save()
    
    // Fetch again to verify the update
    let verifiedConfig = try await config.fetch()
    print("Verified config: \(verifiedConfig)")
    print("Winning number is now: \(verifiedConfig.winningNumber ?? 0)")
} catch {
    print("Error: \(error)")
}
