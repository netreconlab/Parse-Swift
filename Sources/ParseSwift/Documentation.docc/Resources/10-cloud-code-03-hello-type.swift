import Foundation
import ParseSwift

// Create a ParseCloudable type for the "hello" Cloud Function
struct Hello: ParseCloudable {
    // The Cloud Function returns a String
    typealias ReturnType = String
    
    // The name of the Cloud Function on the server
    var functionJobName: String = "hello"
}
