import Foundation
import ParseSwift

// ❌ Bad: Tracking too frequently
func textFieldDidChange(_ text: String) {
    // Don't track every keystroke!
    var event = ParseAnalytics(name: "textChanged")
    event.track { _ in }
}

// ✅ Good: Track meaningful milestones
func searchCompleted(query: String, resultCount: Int) {
    // Track when user completes a search
    // Note: Don't include sensitive data like actual query text
    var searchEvent = ParseAnalytics(name: "searchPerformed")
    searchEvent.track(dimensions: [
        "hasResults": resultCount > 0 ? "true" : "false",
        "queryLength": "\(query.count)"
    ]) { _ in }
}

func tutorialStepCompleted(step: Int) {
    // Track important progress points
    var stepEvent = ParseAnalytics(name: "tutorialStepCompleted")
    stepEvent.track(dimensions: ["step": "\(step)"]) { _ in }
}
