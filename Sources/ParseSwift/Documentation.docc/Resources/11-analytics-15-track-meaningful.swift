import Foundation
import ParseSwift

// ❌ Bad: Tracking too frequently
func textFieldDidChange(_ text: String) {
    // Don't track every keystroke!
    var event = ParseAnalytics(name: "textChanged")
    event.track { _ in }
}

// ✅ Good: Track meaningful milestones
func searchCompleted(query: String) {
    // Track when user completes a search
    var searchEvent = ParseAnalytics(name: "searchPerformed")
    searchEvent.track(dimensions: ["query": query]) { _ in }
}

func tutorialStepCompleted(step: Int) {
    // Track important progress points
    var stepEvent = ParseAnalytics(name: "tutorialStepCompleted")
    stepEvent.track(dimensions: ["step": "\(step)"]) { _ in }
}
