import Foundation
import ParseSwift

var query = GameScore.query("points" < 11)

Task {
    do {
        // Subscribe to your query using callbacks
        let subscription = try await query.subscribeCallback()
        print("Subscription created successfully")
    } catch {
        print("Error subscribing: \(error)")
    }
}
