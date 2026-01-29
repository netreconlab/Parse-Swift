import Foundation
import ParseSwift

var myFunction = ParseHookFunction(
    name: "foo",
    url: URL(string: "https://api.example.com/foo")!
)

// Register the Hook Function with Parse Server
do {
    let created = try await myFunction.create()
    print("Created Hook Function: \(created)")
} catch {
    print("Failed to create Hook Function: \(error)")
}
