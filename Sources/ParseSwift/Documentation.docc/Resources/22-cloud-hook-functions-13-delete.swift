import Foundation
import ParseSwift

var myFunction = ParseHookFunction(
    name: "foo",
    url: URL(string: "https://api.example.com/foo")!
)

// Delete the Hook Function from Parse Server
do {
    try await myFunction.delete()
    print("Hook Function deleted successfully")
} catch {
    print("Failed to delete Hook Function: \(error)")
}
