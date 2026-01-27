import Foundation
import ParseSwift

var query = GameScore.query("points" < 11)

Task {
    do {
        // Unsubscribe from a query when you no longer need updates
        try await query.unsubscribe()
        print("Successfully unsubscribed from query")

        // If this was the last subscription, the WebSocket connection
        // will automatically close
    } catch {
        print("Error unsubscribing: \(error)")
    }
}
