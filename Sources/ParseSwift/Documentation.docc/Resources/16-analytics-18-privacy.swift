import Foundation
import ParseSwift

// Respect user privacy preferences
class AnalyticsManager {
    // Allow users to opt out of analytics
    static var isAnalyticsEnabled: Bool {
        get {
            let defaults = UserDefaults.standard
            // Default to analytics enabled until the user explicitly opts out
            if defaults.object(forKey: "analyticsEnabled") == nil {
                return true
            }
            return defaults.bool(forKey: "analyticsEnabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "analyticsEnabled")
        }
    }
    
    // Only track if the user hasn't opted out of analytics
    static func trackEvent(name: String, dimensions: [String: String]? = nil) {
        guard isAnalyticsEnabled else {
            return
        }
        
        var event = ParseAnalytics(name: name)
        event.track(dimensions: dimensions) { result in
            switch result {
            case .success:
                print("Event tracked: \(name)")
            case .failure(let error):
                print("Failed to track event: \(error)")
            }
        }
    }
}

// Usage
AnalyticsManager.trackEvent(name: "featureUsed", dimensions: ["feature": "export"])
