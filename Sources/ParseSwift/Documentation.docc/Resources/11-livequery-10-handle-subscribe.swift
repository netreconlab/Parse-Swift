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
        
        // Handle subscription success notifications
        subscription.handleSubscribe { subscribedQuery, isNew in
            // You can check if this subscription is for this query
            if isNew {
                print("Successfully subscribed to new query: \(subscribedQuery)")
            } else {
                print("Successfully updated subscription to query: \(subscribedQuery)")
            }
        }
    } catch {
        print("Error subscribing: \(error)")
    }
}
