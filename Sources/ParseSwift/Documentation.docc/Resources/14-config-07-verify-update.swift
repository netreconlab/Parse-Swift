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

        // WARNING: ParseConfig.save() uses the Parse primary/master key.
        // This example is intended for trusted server-side/admin tooling only,
        // where the primary key can be stored securely. Do NOT call config.save()
        // from untrusted client applications (such as iOS, macOS, or other
        // end-user apps), and do not embed the primary/master key in client code.
        // Client apps should typically only read config via fetch, while updates
        // are performed by secure backend or admin tools.
        let isUpdated = try await config.save()

        if isUpdated {
            // Fetch again to verify the update
            let verifiedConfig = try await config.fetch()
            print("Verified config: \(verifiedConfig)")
            print("Winning number is now: \(verifiedConfig.winningNumber ?? 0)")
        } else {
            print("Config save did not report an update; skipping verification fetch.")
        }
    } catch {
        print("Error: \(error)")
    }
}
