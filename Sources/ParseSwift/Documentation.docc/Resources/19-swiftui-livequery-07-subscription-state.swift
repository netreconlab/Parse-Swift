import Foundation
import ParseSwift
import SwiftUI

struct ContentView: View {
    @StateObject var subscription: Subscription<GameScore>

    var body: some View {
        VStack {
            // Check the subscription state
            if subscription.isSubscribed {
                Text("Subscribed to query!")
            } else if subscription.isUnsubscribed {
                Text("Unsubscribed from query!")
            } else {
                Text("Not subscribed to a query")
            }
            Spacer()
        }
    }
}
