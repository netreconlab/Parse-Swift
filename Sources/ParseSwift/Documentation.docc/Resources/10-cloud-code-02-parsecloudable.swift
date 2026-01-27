import Foundation
import ParseSwift

// Define a type that conforms to ParseCloudable
struct MyCloudFunction: ParseCloudable {
    // Specify the return type from the Cloud Function
    typealias ReturnType = String
    
    // Specify the name of the Cloud Function on the server
    var functionJobName: String = "myFunctionName"
}
