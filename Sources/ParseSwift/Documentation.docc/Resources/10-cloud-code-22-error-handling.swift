import Foundation
import ParseSwift

struct ProcessOrder: ParseCloudable {
    typealias ReturnType = [String: Any]
    var functionJobName: String = "processOrder"
    var orderId: String
}

let processOrder = ProcessOrder(orderId: "ORD12345")

Task {
    do {
        let result = try await processOrder.runFunction()
        print("Order processed successfully: \(result)")
    } catch let error as ParseError {
        // Handle Parse-specific errors
        switch error.code {
        case .other:
            if let code = error.otherCode {
                // Handle custom error codes from Cloud Code
                switch code {
                case 4001:
                    print("Insufficient inventory")
                case 4002:
                    print("Payment method declined")
                case 4003:
                    print("Invalid shipping address")
                default:
                    print("Order processing failed: \(error.message ?? "Unknown error")")
                }
            }
        case .connectionFailed:
            print("Network error, please try again")
        default:
            print("Error: \(error.message ?? "Unknown error")")
        }
    } catch {
        print("Unexpected error: \(error)")
    }
}
