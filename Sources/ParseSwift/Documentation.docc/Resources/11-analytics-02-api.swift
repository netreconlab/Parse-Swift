import Foundation
import ParseSwift

Task {
    do {
        // Track app opened
        try await ParseAnalytics.trackAppOpened()

        // Track custom events
        var event = ParseAnalytics(name: "eventName")
        try await event.track()

        // Track with dimensions
        try await event.track(dimensions: ["key": "value"])
    } catch {
        print("Error tracking analytics: \(error)")
    }
}
