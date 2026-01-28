import Foundation
import ParseSwift

var myFunction = ParseHookFunction(
    name: "foo",
    url: URL(string: "https://api.example.com/foo")!
)

myFunction.url = URL(string: "https://api.example.com/bar")!

// Save the updated Hook Function to Parse Server
do {
    let updated = try await myFunction.update()
    print("Updated Hook Function: \(updated)")
} catch {
    print("Failed to update Hook Function: \(error)")
}
