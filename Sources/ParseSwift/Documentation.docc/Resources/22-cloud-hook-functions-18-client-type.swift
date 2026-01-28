import Foundation
import ParseSwift

// Define a ParseCloudable type matching the Hook Function name
struct MyCloudFunction: ParseCloudable {
    typealias ReturnType = String
    
    var functionJobName: String = "foo"
    
    // Add parameters to pass to the webhook
    var argument1: String
}
