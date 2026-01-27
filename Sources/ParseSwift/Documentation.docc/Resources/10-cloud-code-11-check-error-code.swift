import Foundation
import ParseSwift

let testCloudCodeError = TestCloudCodeError()

Task {
    do {
        let response = try await testCloudCodeError.runFunction()
        print("Response: \(response)")
    } catch let error as ParseError {
        // Check if this is a custom Cloud Code error
        switch error.code {
        case .other:
            // Access the custom error code
            if let otherCode = error.otherCode {
                // Handle specific custom error codes
                switch otherCode {
                case 3000:
                    print("Received Cloud Code error: \(error)")
                    // Output: "Received Cloud Code error: ParseError..."
                default:
                    print("Received unknown error code: \(otherCode)")
                }
            } else {
                print("Error doesn't have a custom code")
            }
        default:
            print("Received standard Parse error: \(error)")
        }
    } catch {
        print("Unexpected error: \(error)")
    }
}
