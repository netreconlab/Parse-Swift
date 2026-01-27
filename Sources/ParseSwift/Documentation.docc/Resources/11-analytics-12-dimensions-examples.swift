import Foundation
import ParseSwift

Task {
    do {
        // Example 1: Track video playback with details
        var videoEvent = ParseAnalytics(name: "videoPlayed")
        try await videoEvent.track(dimensions: [
            "category": "tutorial",
            "duration": "5min",
            "quality": "HD"
        ])

        // Example 2: Track feature usage with user context
        var featureEvent = ParseAnalytics(name: "premiumFeatureUsed")
        try await featureEvent.track(dimensions: [
            "subscriptionTier": "pro",
            "userLevel": "advanced"
        ])
    } catch {
        print("Error tracking events: \(error)")
    }
}
