import Foundation
import ParseSwift

// Create an instance of the Hello Cloud Function
let hello = Hello()

do {
    // Call the Cloud Function using async/await
    let response = try await hello.runFunction()
} catch {
    print("Error calling cloud function: \(error)")
}
