import Foundation
import ParseSwift

// Fetch all Hook Functions using the type method
do {
    let allFunctions = try await ParseHookFunction.fetchAll()
    print("Found \(allFunctions.count) Hook Functions")
    for function in allFunctions {
        print("- \(function.name): \(function.url)")
    }
} catch {
    print("Failed to fetch Hook Functions: \(error)")
}
