import Foundation
import ParseSwift

var myFunction = ParseHookFunction(
    name: "foo",
    url: URL(string: "https://api.example.com/foo")!
)

// Fetch the current configuration from Parse Server
do {
    let fetched = try await myFunction.fetch()
    print("Fetched Hook Function: \(fetched)")
} catch {
    print("Failed to fetch Hook Function: \(error)")
}
