import Foundation
import ParseSwift

// Create a ParseCloudable type for a function that throws errors
struct TestCloudCodeError: ParseCloudable {
    // The Cloud Function would return a String if successful
    typealias ReturnType = String

    // The name of the Cloud Function on the server
    var functionJobName: String = "testCloudCodeError"
}
