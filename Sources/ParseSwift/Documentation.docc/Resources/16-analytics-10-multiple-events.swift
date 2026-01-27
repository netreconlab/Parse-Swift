import Foundation
import ParseSwift

// Track different events throughout your app using completion handlers
func trackUserActions() {
    // Track when user views their profile
    var profileEvent = ParseAnalytics(name: "viewedProfile")
    profileEvent.track { result in
        if case let .failure(error) = result {
            print("Error tracking viewedProfile: \(error)")
        }
    }
    
    // Track when user sends a message
    var messageEvent = ParseAnalytics(name: "sentMessage")
    messageEvent.track { result in
        if case let .failure(error) = result {
            print("Error tracking sentMessage: \(error)")
        }
    }
    
    // Track when user shares content
    var shareEvent = ParseAnalytics(name: "sharedContent")
    shareEvent.track { result in
        if case let .failure(error) = result {
            print("Error tracking sharedContent: \(error)")
        }
    }
}
