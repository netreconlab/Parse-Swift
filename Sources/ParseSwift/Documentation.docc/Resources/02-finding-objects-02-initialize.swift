import Foundation
import ParseSwift

Task {
    do {
        try await ParseSwift.initialize(
            applicationId: "applicationId",
            clientKey: "clientKey",
            serverURL: URL(string: "http://localhost:1337/parse")!
        )
        print("Parse SDK initialized successfully")
    } catch {
        print("Error initializing Parse: \(error)")
    }
}
