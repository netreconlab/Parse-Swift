import Foundation
import ParseSwift

// Track when the app is opened using async/await
func trackAppLaunch() async {
    do {
        try await ParseAnalytics.trackAppOpened()
        print("Successfully tracked app opened event")
    } catch {
        print("Error tracking app opened: \(error)")
    }
}
