import Foundation
import ParseSwift

let testCloudCodeError = TestCloudCodeError()

do {
    // Attempt to call the Cloud Function
    let response = try await testCloudCodeError.runFunction()
    print("Response: \(response)")
} catch let error as ParseError {
    // Handle Parse-specific errors
    print("ParseError occurred: \(error)")
} catch {
    // Handle other errors
    print("Unexpected error: \(error)")
}
