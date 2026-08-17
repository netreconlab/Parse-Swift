import Foundation
import ParseSwift

struct MyCloudFunction: ParseCloudable {
    typealias ReturnType = String
    var functionJobName: String = "foo"
    var argument1: String
}

// Call the Hook Function from your client app
do {
    let cloudFunction = MyCloudFunction(argument1: "test")
    let result = try await cloudFunction.runFunction()
    // Parse Server executed your webhook and returned the result
    print("Function result: \(result)")
} catch {
    print("Function call failed: \(error)")
}
