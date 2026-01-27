import Foundation
import ParseSwift
import SwiftUI

// To use subscriptions inside of SwiftUI
struct ContentView: View {

    // A LiveQuery subscription can be used as a view model in SwiftUI
    @StateObject var subscription: Subscription<GameScore>

    var body: some View {
        VStack {
            Text("Not subscribed to a query")
            Spacer()
        }
    }
}
