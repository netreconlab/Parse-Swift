import Foundation
import ParseSwift

// Create a query just as you normally would
var query = GameScore.query("points" < 11)
print("Created query for GameScore with points < 11")

Task {
    do {
        // Subscribe to your query using callbacks
        let subscription = try await query.subscribeCallback()
        print("Subscription created successfully")
    } catch {
        print("Error subscribing: \(error)")
    }
}
