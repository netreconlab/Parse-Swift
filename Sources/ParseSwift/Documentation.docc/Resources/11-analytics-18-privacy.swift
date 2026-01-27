import Foundation
import ParseSwift

// Respect user privacy preferences
class AnalyticsManager {
    // Allow users to opt out of analytics
    static var isAnalyticsEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: "analyticsEnabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "analyticsEnabled")
        }
    }
    
    // Only track if user has given consent
    static func trackEvent(name: String, dimensions: [String: String]? = nil) {
        guard isAnalyticsEnabled else {
            print("Analytics disabled by user preference")
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
