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
    
    // Save the updated configuration to the server
    let isUpdated = try await config.save()
    
    if isUpdated {
        print("Configuration successfully updated on the server")
    } else {
        print("Configuration update failed")
    }
} catch {
    print("Error saving config: \(error)")
}
