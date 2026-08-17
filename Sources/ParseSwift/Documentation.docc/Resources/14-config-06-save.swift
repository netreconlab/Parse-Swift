import Foundation
import ParseSwift

struct Config: ParseConfig {
    var welcomeMessage: String?
    var winningNumber: Int?
}

var config = Config()

Task {
    do {
        config = try await config.fetch()
        config.winningNumber = 50

        // Save the updated configuration to the server.
        // WARNING: ParseConfig.save() uses the primary/master key and should only be
        // called from trusted server-side/admin code. Do NOT use this pattern from
        // untrusted client applications; prefer Parse Dashboard or Cloud Code instead.
        let isUpdated = try await config.save()

        if isUpdated {
            print("Configuration successfully updated on the server")
        } else {
            print("Configuration update failed")
        }
    } catch {
        print("Error saving config: \(error)")
    }
}
