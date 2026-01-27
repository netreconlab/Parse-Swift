import Foundation
import ParseSwift

// Create a ParseCloudable type for a Cloud Job
struct MyBackgroundJob: ParseCloudable {
    // The return type for the job
    typealias ReturnType = String

    // The name of the Cloud Job on the server
    var functionJobName: String = "myBackgroundJob"

    // Optional: Add any parameters the job needs
    var batchSize: Int?
}
