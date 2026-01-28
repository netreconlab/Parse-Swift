import Foundation
import ParseSwift
import SwiftUI

struct GameScore: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?
    var points: Int? = 0
    var location: ParseGeoPoint?
    var name: String?

    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.points,
                                     original: object) {
            updated.points = object.points
        }
        if updated.shouldRestoreKey(\.name,
                                     original: object) {
            updated.name = object.name
        }
        if updated.shouldRestoreKey(\.location,
                                     original: object) {
            updated.location = object.location
        }
        return updated
    }
}

extension GameScore {
    init(name: String, points: Int) {
        self.name = name
        self.points = points
    }
}

var query = GameScore.query("points" < 11)

struct ContentView: View {
    @StateObject var subscription: Subscription<GameScore>

    var body: some View {
        VStack {
            if subscription.isSubscribed {
                Text("Subscribed to query!")
            } else if subscription.isUnsubscribed {
                Text("Unsubscribed from query!")
            } else if let event = subscription.event {
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

            Text("Update GameScore in Parse Dashboard to see changes here:")

            Button(action: {
                Task {
                    try? await subscription.query.unsubscribe(subscription)
                }
            }, label: {
                Text("Unsubscribe")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(20.0)
            })
            Spacer()
        }
    }
}

@MainActor
func startView() async throws -> ContentView {
    let subscribe = try await query.subscribe()
    // Return the ContentView with the subscription
    return ContentView(subscription: subscribe)
}

// In your App or SceneDelegate, after initializing ParseSwift:
Task {
    do {
        let contentView = try await startView()
        // Use contentView with UIHostingController or in your SwiftUI App
        // Example: UIHostingController(rootView: contentView)
    } catch {
        print("Error subscribing: \(error)")
    }
}
