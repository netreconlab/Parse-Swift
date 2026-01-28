import Foundation
import ParseSwift

var myFunction = ParseHookFunction(
    name: "foo",
    url: URL(string: "https://api.example.com/foo")!
)

do {
    let created = try await myFunction.create()
    // Success - the Hook Function is now registered
    print("Successfully created Hook Function: \(created.name)")
    print("Webhook URL: \(created.url)")
} catch {
    // Handle errors like duplicate function names or network issues
    print("Failed to create Hook Function: \(error)")
}
