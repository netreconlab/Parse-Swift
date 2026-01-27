import Foundation
import ParseSwift

// Track app opened using completion handler
ParseAnalytics.trackAppOpened { result in
    switch result {
    case .success:
        print("Tracked app opened")
    case .failure(let error):
        print("Error tracking app opened: \(error)")
    }
}

// Track custom events using completion handler
var event = ParseAnalytics(name: "eventName")
event.track { result in
    switch result {
    case .success:
        print("Tracked custom event")
    case .failure(let error):
        print("Error tracking custom event: \(error)")
    }
}

// Track with dimensions using completion handler
event.track(dimensions: ["key": "value"]) { result in
    switch result {
    case .success:
        print("Tracked event with dimensions")
    case .failure(let error):
        print("Error tracking event with dimensions: \(error)")
    }
}
