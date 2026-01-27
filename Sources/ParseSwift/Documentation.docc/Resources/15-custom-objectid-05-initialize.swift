import Foundation
import ParseSwift

Task {
    do {
        try await ParseSwift.initialize(
            applicationId: "applicationId",
            clientKey: "clientKey",
            serverURL: URL(string: "http://localhost:1337/parse")!,
            customObjectId: true  // Enable custom objectId support
        )
        print("Parse initialized with custom objectId support")
    } catch {
        print("Error initializing Parse: \(error)")
    }
}
