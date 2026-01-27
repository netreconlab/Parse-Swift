import Foundation
import ParseSwift

// Track an event with additional context using dimensions
var friendEvent = ParseAnalytics(name: "openedFriendList")

friendEvent.track(dimensions: ["more": "info"]) { result in
    switch result {
    case .success:
        print("Saved analytics for custom event with dimensions.")
    case .failure(let error):
        print("Error tracking event: \(error)")
    }
}
