import Foundation
import ParseSwift

var myFunction = ParseHookFunction(
    name: "foo",
    url: URL(string: "https://api.example.com/foo")!
)

do {
    try await myFunction.delete()
    // Success - the Hook Function is no longer registered
    print("Hook Function deleted successfully")
    // The function name is now available for reuse
} catch {
    print("Failed to delete Hook Function: \(error)")
}
