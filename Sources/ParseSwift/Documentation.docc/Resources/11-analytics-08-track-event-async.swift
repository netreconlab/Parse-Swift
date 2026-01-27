import Foundation
import ParseSwift

// Track a custom event using async/await
var friendEvent = ParseAnalytics(name: "openedFriendList")

do {
    try await friendEvent.track()
    print("Successfully tracked custom event")
} catch {
    print("Error tracking event: \(error)")
}
