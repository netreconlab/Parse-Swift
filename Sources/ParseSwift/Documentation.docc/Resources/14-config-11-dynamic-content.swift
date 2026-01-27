import Foundation
import ParseSwift

// Use configuration for dynamic content
struct Config: ParseConfig {
    var welcomeMessage: String?
    var winningNumber: Int?
    
    // Dynamic content
    var promotionalMessage: String?
    var maintenanceMessage: String?
    var announcementText: String?
}

var config = Config()

do {
    config = try await config.fetch()
    
    // Display dynamic content
    if let promo = config.promotionalMessage {
        print("Showing promotional message: \(promo)")
        // Display in UI
    }
    
    if let announcement = config.announcementText {
        print("Announcement: \(announcement)")
        // Show announcement banner
    }
} catch {
    print("Error: \(error)")
}
