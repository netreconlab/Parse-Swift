import Foundation
import ParseSwift

// Define a ParseConfig struct that matches your server configuration
struct Config: ParseConfig {
    // Configuration parameters - names and types must match Parse Dashboard settings
    var welcomeMessage: String?
    var winningNumber: Int?
}
