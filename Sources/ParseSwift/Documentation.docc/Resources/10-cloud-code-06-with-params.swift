import Foundation
import ParseSwift

// Create a ParseCloudable type with parameters
struct TestCloudCode: ParseCloudable {
    // The Cloud Function returns a dictionary
    typealias ReturnType = [String: Int]

    // The name of the Cloud Function on the server
    var functionJobName: String = "testCloudCode"

    // Custom parameter that will be sent to the Cloud Function
    // This will be available as request.params.argument1 on the server
    var argument1: [String: Int]
}
