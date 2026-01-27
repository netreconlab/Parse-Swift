import Foundation
import ParseSwift

var query = GameScore.query("points" < 11)

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
        
        // Register for unsubscribe notifications
        subscription.handleUnsubscribe { query in
            print("Unsubscribed from query: \(query)")
        }
    } catch {
        print("Error subscribing: \(error)")
    }
}
