import Foundation
import ParseSwift

var myFunction = ParseHookFunction(
    name: "foo",
    url: URL(string: "https://api.example.com/foo")!
)

do {
    let created = try await myFunction.create()
    // Success - the Hook Function is now registered
    print("Successfully created Hook Function: \(created.functionName ?? "unknown")")
    print("Webhook URL: \(created.url?.absoluteString ?? "unknown")")
} catch {
    // Handle errors like duplicate function names or network issues
    print("Failed to create Hook Function: \(error)")
}
