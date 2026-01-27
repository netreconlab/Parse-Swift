import Foundation
import ParseSwift

// Track a custom event using completion handler
var friendEvent = ParseAnalytics(name: "openedFriendList")

friendEvent.track { result in
    switch result {
    case .success:
        print("Saved analytics for custom event.")
    case .failure(let error):
        print("Error tracking event: \(error)")
    }
}
