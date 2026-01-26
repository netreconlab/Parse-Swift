import Foundation
import ParseSwift

// Initialize Parse SDK
Task {
    do {
        try await ParseSwift.initialize(
            applicationId: "YOUR_APP_ID",
            clientKey: "YOUR_CLIENT_KEY",
            serverURL: URL(string: "http://localhost:1337/parse")!
        )
        print("Parse SDK initialized successfully")
    } catch {
        print("Error initializing Parse SDK: \(error)")
    }
}
