import Foundation
import ParseSwift

// Track different events throughout your app
func trackUserActions() async {
    do {
        // Track when user views their profile
        var profileEvent = ParseAnalytics(name: "viewedProfile")
        try await profileEvent.track()
        
        // Track when user sends a message
        var messageEvent = ParseAnalytics(name: "sentMessage")
        try await messageEvent.track()
        
        // Track when user shares content
        var shareEvent = ParseAnalytics(name: "sharedContent")
        try await shareEvent.track()
    } catch {
        print("Error tracking events: \(error)")
    }
}
