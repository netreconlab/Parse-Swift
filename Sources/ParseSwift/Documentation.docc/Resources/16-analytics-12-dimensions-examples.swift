import Foundation
import ParseSwift

// Example 1: Track video playback with details
var videoEvent = ParseAnalytics(name: "videoPlayed")
videoEvent.track(dimensions: [
    "category": "tutorial",
    "duration": "5min",
    "quality": "HD"
]) { result in
    switch result {
    case .success:
        print("Tracked video event")
    case .failure(let error):
        print("Error tracking video event: \(error)")
    }
}

// Example 2: Track feature usage with user context
var featureEvent = ParseAnalytics(name: "premiumFeatureUsed")
featureEvent.track(dimensions: [
    "subscriptionTier": "pro",
    "userLevel": "advanced"
]) { result in
    switch result {
    case .success:
        print("Tracked feature event")
    case .failure(let error):
        print("Error tracking feature event: \(error)")
    }
}
