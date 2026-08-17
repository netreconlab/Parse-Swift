import Foundation
import ParseSwift
import SwiftUI

struct ContentView: View {
    @StateObject var subscription: Subscription<GameScore>

    var body: some View {
        VStack {
            if subscription.isSubscribed {
                Text("Subscribed to query!")
            } else if subscription.isUnsubscribed {
                Text("Unsubscribed from query!")
            } else if let event = subscription.event {
                // This is how you register to receive notifications
                // of events related to your LiveQuery
                switch event.event {
                case .entered(let object):
                    Text("Entered with points: \(String(describing: object.points))")
                case .left(let object):
                    Text("Left with points: \(String(describing: object.points))")
                case .created(let object):
                    Text("Created with points: \(String(describing: object.points))")
                case .updated(let object):
                    Text("Updated with points: \(String(describing: object.points))")
                case .deleted(let object):
                    Text("Deleted with points: \(String(describing: object.points))")
                }
            } else {
                Text("Not subscribed to a query")
            }
            Spacer()
        }
    }
}
