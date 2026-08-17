import Foundation
import ParseSwift

var myFunction = ParseHookFunction(
    name: "foo",
    url: URL(string: "https://api.example.com/foo")!
)

do {
    let fetched = try await myFunction.fetch()
    // Verify the function configuration
    print("Function name: \(fetched.functionName ?? "unknown")")
    print("Webhook URL: \(fetched.url?.absoluteString ?? "unknown")")
} catch {
    // Handle cases where the function doesn't exist
    print("Hook Function not found: \(error)")
}
