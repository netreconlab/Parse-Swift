import Foundation
import ParseSwift

var query = GameScore.query("points" < 11)
var query2 = GameScore.query("points" > 50)
query2.select("points")

Task {
    do {
        // Resubscribe to a query that was never unsubscribed
        // Since we never unsubscribed, you can reuse your previous handlers
        let subscription3 = try await query2.subscribeCallback()
        print("Resubscribed to existing query")

        // Resubscribe to a query that was previously unsubscribed
        // This one needs new handlers
        let subscription4 = try await query.subscribeCallback()
        print("Resubscribed to previously unsubscribed query")

        // Set up new subscription handler
        subscription4.handleSubscribe { subscribedQuery, isNew in
            if isNew {
                print("Successfully subscribed to new query: \(subscribedQuery)")
            } else {
                print("Successfully updated subscription to query: \(subscribedQuery)")
            }
        }

        // Set up new event handler
        subscription4.handleEvent { _, event in
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

        // Set up new unsubscribe handler
        subscription4.handleUnsubscribe { query in
            print("Unsubscribed from query: \(query)")
        }
    } catch {
        print("Error resubscribing: \(error)")
    }
}
