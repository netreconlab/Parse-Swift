import Foundation
import ParseSwift

Task {
    do {
        try await ParseSwift.initialize(
            applicationId: "applicationId",
            clientKey: "clientKey",
            primaryKey: "primaryKey",
            serverURL: URL(string: "http://localhost:1337/parse")!
        )

        let version = try await ParseVersion.current()
        print("Current Swift SDK version is \"\(version)\"")

        let health = try await ParseServer.health()
        print("Server health is: \(health)")
    } catch {
        print("Error checking server health: \(error)")
    }
}
