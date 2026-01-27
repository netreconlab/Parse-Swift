import Foundation
import ParseSwift

// Track when the app is opened using completion handler
ParseAnalytics.trackAppOpened { result in
    switch result {
    case .success:
        print("Successfully tracked app opened event")
    case .failure(let error):
        print("Error tracking app opened: \(error)")
    }
}
