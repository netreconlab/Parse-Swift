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

        // Handle all subscription events
        subscription2.handleEvent { _, event in
            switch event {
            case .entered(let object):
                print("Object entered query: \(object)")
            case .left(let object):
                print("Object left query: \(object)")
            case .created(let object):
                print("Object created: \(object)")
            case .updated(let object):
                print("Object updated: \(object)")
            case .deleted(let object):
                print("Object deleted: \(object)")
            }
        }

        // Now you can modify GameScore objects in your dashboard
        // and you will receive real-time notifications
    } catch {
        print("Error subscribing: \(error)")
    }
}
