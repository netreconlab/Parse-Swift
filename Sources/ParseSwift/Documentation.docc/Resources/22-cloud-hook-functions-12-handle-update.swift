import Foundation
import ParseSwift

var myFunction = ParseHookFunction(
    name: "foo",
    url: URL(string: "https://api.example.com/foo")!
)

myFunction.url = URL(string: "https://api.example.com/bar")!

do {
    let updated = try await myFunction.update()
    // Verify the URL was updated successfully
    print("Updated Hook Function URL to: \(updated.url)")
} catch {
    print("Failed to update Hook Function: \(error)")
}
