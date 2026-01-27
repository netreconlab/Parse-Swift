import Foundation
import ParseSwift

// Create an instance with parameter values
let testCloudCode = TestCloudCode(argument1: ["test": 5])

do {
    // Call the Cloud Function with parameters
    let response = try await testCloudCode.runFunction()
    
    // Process the response
    print("Response from cloud function: \(response)")
    // Output: "Response from cloud function: ["test": 5]"
} catch {
    print("Error: \(error.localizedDescription)")
}
