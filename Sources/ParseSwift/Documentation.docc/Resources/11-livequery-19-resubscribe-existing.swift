import Foundation
import ParseSwift

var query2 = GameScore.query("points" > 50)
query2.select("points")

Task {
    do {
        // Resubscribe to a query that was never unsubscribed
        // Since we never unsubscribed, you can reuse your previous handlers
        let subscription3 = try await query2.subscribeCallback()
        print("Resubscribed to existing query")
        
        // The previous event handlers are still active
    } catch {
        print("Error resubscribing: \(error)")
    }
}
