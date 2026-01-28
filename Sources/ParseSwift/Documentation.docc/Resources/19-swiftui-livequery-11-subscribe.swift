import Foundation
import ParseSwift
import SwiftUI

@MainActor
func startView() async throws -> ContentView {
    // Subscribe to the query
    let subscribe = try await query.subscribe()
    // Return the ContentView with the subscription
    return ContentView(subscription: subscribe)
}
