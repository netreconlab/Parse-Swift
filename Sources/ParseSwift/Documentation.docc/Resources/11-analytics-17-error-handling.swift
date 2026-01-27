import Foundation
import ParseSwift

// Analytics should never interrupt user experience
func trackUserAction() {
    var event = ParseAnalytics(name: "importantAction")
    
    // ✅ Good: Silent error handling
    event.track { result in
        switch result {
        case .success:
            // Optionally log success for debugging
            print("Analytics tracked successfully")
        case .failure(let error):
            // Log error but don't show to user
            print("Analytics tracking failed: \(error)")
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
