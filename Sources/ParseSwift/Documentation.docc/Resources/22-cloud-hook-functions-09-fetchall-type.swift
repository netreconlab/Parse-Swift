import Foundation
import ParseSwift

// Fetch all Hook Functions using the type method
do {
    let allFunctions = try await ParseHookFunction.fetchAll()
    print("Found \(allFunctions.count) Hook Functions")
    for function in allFunctions {
        print("- \(function.functionName ?? "unknown"): \(function.url?.absoluteString ?? "unknown")")
    }
} catch {
    print("Failed to fetch Hook Functions: \(error)")
}
