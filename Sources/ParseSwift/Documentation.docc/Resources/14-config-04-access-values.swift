import Foundation
import ParseSwift

struct Config: ParseConfig {
    var welcomeMessage: String?
    var winningNumber: Int?
}

var config = Config()

Task {
    do {
        let fetchedConfig = try await config.fetch()
        
        // Access configuration values
        if let message = fetchedConfig.welcomeMessage {
            print("Welcome message: \(message)")
        }
        
        if let number = fetchedConfig.winningNumber {
            print("Winning number: \(number)")
        }
    } catch {
        print("Error fetching config: \(error)")
    }
}
