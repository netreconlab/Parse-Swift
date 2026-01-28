import Foundation
import ParseSwift

var myFunction = ParseHookFunction(
    name: "foo",
    url: URL(string: "https://api.example.com/foo")!
)

// Fetch all Hook Functions using the instance method
do {
    let allFunctions = try await myFunction.fetchAll()
    print("Found \(allFunctions.count) Hook Functions")
    for function in allFunctions {
        print("- \(function.name): \(function.url)")
    }
} catch {
    print("Failed to fetch Hook Functions: \(error)")
}
