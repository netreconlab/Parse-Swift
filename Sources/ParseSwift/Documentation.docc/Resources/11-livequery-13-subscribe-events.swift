import Foundation
import ParseSwift

// Create a new query for GameScore objects with points > 50
var query2 = GameScore.query("points" > 50)

// Select the fields you are interested in receiving
query2.select("points")
print("Created query with field selection")

Task {
    do {
        // Subscribe to the new query
        let subscription2 = try await query2.subscribeCallback()
        print("Subscription created successfully")
        
        // Handle subscription notifications
        subscription2.handleSubscribe { subscribedQuery, isNew in
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
