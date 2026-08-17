import Foundation
import ParseSwift

Task {
    do {
        try await ParseSwift.initialize(
            applicationId: "applicationId",
            clientKey: "clientKey",
            primaryKey: "primaryKey",
            serverURL: URL(string: "http://localhost:1337/parse")!,
            requiringCustomObjectIds: false,
            usingEqualQueryConstraint: false,
            usingDataProtectionKeychain: false
        )
        print("Parse SDK initialized successfully")
    } catch {
        print("Error initializing Parse-Swift: \(error)")
    }
}
