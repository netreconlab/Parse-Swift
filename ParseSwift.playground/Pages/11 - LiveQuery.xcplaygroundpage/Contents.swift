//: [Previous](@previous)

import PlaygroundSupport
import Foundation
import ParseSwift
import SwiftUI

PlaygroundPage.current.needsIndefiniteExecution = true

//: Be sure you have LiveQuery enabled on your server.

//: Create a delegate for LiveQuery errors
class LiveQueryDelegate: ParseLiveQueryDelegate {

    func received(_ error: Error) {
        print(error)
    }

    func closedSocket(_ code: URLSessionWebSocketTask.CloseCode?, reason: Data?) {
        print("Socket closed with \(String(describing: code)) and \(String(describing: reason))")
    }
}

Task {
    do {
        try await initializeParse()
    } catch {
        assertionFailure("Error initializing Parse-Swift: \(error)")
    }
}

//: Create your own value typed ParseObject.
struct GameScore: ParseObject {
    //: These are required by `ParseObject`.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    //: Your own properties.
    var points: Int?
    var location: ParseGeoPoint?
    var name: String?

    /*:
     Optional - implement your own version of merge
     for faster decoding after updating your `ParseObject`.
     */
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.points,
                                     original: object) {
            updated.points = object.points
        }
        if updated.shouldRestoreKey(\.location,
                                     original: object) {
            updated.location = object.location
        }
        if updated.shouldRestoreKey(\.name,
                                     original: object) {
            updated.name = object.name
        }
        return updated
    }
}

//: It's recommended to place custom initializers in an extension
//: to preserve the memberwise initializer.
extension GameScore {
    //: Custom initializer.
    init(name: String, points: Int) {
        self.name = name
        self.points = points
    }
}

//: Create a query just as you normally would.
var query = GameScore.query("points" < 11)

Task {
    //: This is how you subscribe to your created query using callbacks.
    do {
        let subscription = try await query.subscribeCallback()

        //: This is how you receive notifications about the success
        //: of your subscription.
        subscription.handleSubscribe { subscribedQuery, isNew in

            //: You can check this subscription is for this query
            if isNew {
                print("Successfully subscribed to new query \(subscribedQuery)")
            } else {
                print("Successfully updated subscription to new query \(subscribedQuery)")
            }
        }

        //: This is how you register to receive notifications about being unsubscribed.
        subscription.handleUnsubscribe { query in
            print("Unsubscribed from \(query)")
        }

        // We will automatically unsubscribe after three seconds to see the callback.
        let nanoSeconds = UInt64(3 * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoSeconds)

        //: To unsubscribe from your query.
        try await query.unsubscribe()

        //: If you look at your server log, you will notice the client and server disconnnected.
        //: This is because there is no more LiveQuery subscriptions.
    } catch {
        assertionFailure("Error subscribing: \(error)")
    }
}

//: This is how you set a delegate for the default client.
let delegate = LiveQueryDelegate()
if let client = ParseLiveQuery.defaultClient {
    client.receiveDelegate = delegate
} else {
    assertionFailure("LiveQuery should have a default client")
}

//: Ping the LiveQuery server
ParseLiveQuery.client?.sendPing { error in
    if let error = error {
        print("Error pinging LiveQuery server: \(error)")
    } else {
        print("Successfully pinged server!")
    }
}

//: Create a new query.
var query2 = GameScore.query("points" > 50)

//: Select the fields you are interested in receiving.
query2.select("points")

Task {
    do {
        //: Subscribe to your new query.
        let subscription2 = try await query2.subscribeCallback()

        //: As before, setup your subscription, event, and unsubscribe handlers.
        subscription2.handleSubscribe { subscribedQuery, isNew in

            //: You can check this subscription is for this query.
            if isNew {
                print("Successfully subscribed to new query \(subscribedQuery)")
            } else {
                print("Successfully updated subscription to new query \(subscribedQuery)")
            }
        }

        subscription2.handleEvent { _, event in
            switch event {

            case .entered(let object):
                print("Entered: \(object)")
            case .left(let object):
                print("Left: \(object)")
            case .created(let object):
                print("Created: \(object)")
            case .updated(let object):
                print("Updated: \(object)")
            case .deleted(let object):
                print("Deleted: \(object)")
            }
        }

        //: Now go to your dashboard, go to the GameScore table and add, update or remove rows.
        //: You should receive notifications for each.
    } catch {
        print("Error: \(error)")
    }
}

Task {
    //: To close the current LiveQuery connection.
    await ParseLiveQuery.client?.close()
}

//: To close all LiveQuery connections use:
// ParseLiveQuery.client?.closeAll()

//: Ping the LiveQuery server. This should produce an error
//: because LiveQuery is disconnected.
ParseLiveQuery.client?.sendPing { error in
    if let error = error {
        print("Error pinging LiveQuery server: \(error)")
    } else {
        print("Successfully pinged server!")
    }
}

Task {
    do {
        //: Resubscribe to your previous query.
        //: Since we never unsubscribed you can use your previous handlers.
        let subscription3 = try await query2.subscribeCallback()

        //: Resubscribe to another previous query.
        //: This one needs new handlers.
        let subscription4 = try await query.subscribeCallback()

        //: Need a new handler because we previously unsubscribed.
        subscription4.handleSubscribe { subscribedQuery, isNew in
            //: You can check this subscription is for this query
            if isNew {
                print("Successfully subscribed to new query \(subscribedQuery)")
            } else {
                print("Successfully updated subscription to new query \(subscribedQuery)")
            }
        }

        //: Need a new event handler because we previously unsubscribed.
        subscription4.handleEvent { _, event in
            switch event {
            case .entered(let object):
                print("Entered: \(object)")
            case .left(let object):
                print("Left: \(object)")
            case .created(let object):
                print("Created: \(object)")
            case .updated(let object):
                print("Updated: \(object)")
            case .deleted(let object):
                print("Deleted: \(object)")
            }
        }

        //: Need a new unsubscribe handler because we previously unsubscribed.
        subscription4.handleUnsubscribe { query in
            print("Unsubscribed from \(query)")
        }

        //: Delay for 2 seconds
        let nanoSeconds = UInt64(2 * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoSeconds)

        //: To unsubscribe from your query.
        do {
            try await query.unsubscribe()
        } catch {
            print(error)
        }
    } catch {
        print("Error: \(error)")
    }
}

//: Ping the LiveQuery server
ParseLiveQuery.client?.sendPing { error in
    if let error = error {
        print("Error pinging LiveQuery server: \(error)")
    } else {
        print("Successfully pinged server!")
    }
}

PlaygroundPage.current.finishExecution()
//: [Next](@next)
