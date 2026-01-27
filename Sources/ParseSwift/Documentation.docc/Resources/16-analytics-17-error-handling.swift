import Foundation
import ParseSwift

// Analytics should never interrupt user experience
func trackUserAction() {
    var event = ParseAnalytics(name: "importantAction")

    // ✅ Good: Error handling that doesn't disrupt user flow
    event.track { result in
        switch result {
        case .success:
            #if DEBUG
            // Optionally log success for debugging
            print("Analytics tracked successfully")
            #endif
        case .failure(let error):
            #if DEBUG
            // Log error but don't show to user
            print("Analytics tracking failed: \(error)")
            #endif
            // Optionally report to error tracking service
        }
    }

    // Continue with normal app functionality regardless of analytics result
    performUserAction()
}

func performUserAction() {
    // The actual user action continues normally
    print("User action completed")
}
