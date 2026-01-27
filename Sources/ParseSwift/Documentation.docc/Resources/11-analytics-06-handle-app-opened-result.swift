import Foundation
import ParseSwift

// Handle the result of tracking app opened
ParseAnalytics.trackAppOpened { result in
    switch result {
    case .success:
        // Analytics event successfully recorded
        print("Saved analytics for app opened.")
    case .failure(let error):
        // Handle error (network issue, server problem, etc.)
        print("Failed to track app opened: \(error)")
    }
}
