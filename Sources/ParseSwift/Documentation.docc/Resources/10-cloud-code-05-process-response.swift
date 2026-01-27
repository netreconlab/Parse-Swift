import Foundation
import ParseSwift

let hello = Hello()

Task {
    do {
        // Call the Cloud Function and get the response
        let response = try await hello.runFunction()
        
        // Process the response
        print("Response from cloud function: \(response)")
        // Output: "Response from cloud function: Hello world!"
    } catch {
        print("Error calling cloud function: \(error)")
    }
}
