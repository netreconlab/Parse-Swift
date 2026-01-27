import Foundation
import ParseSwift

// Good: Each function has a single, clear purpose

struct SendWelcomeEmail: ParseCloudable {
    typealias ReturnType = Bool
    var functionJobName: String = "sendWelcomeEmail"
    var userId: String
}

struct ValidatePromoCode: ParseCloudable {
    typealias ReturnType = [String: Any]
    var functionJobName: String = "validatePromoCode"
    var code: String
}

struct CalculateShipping: ParseCloudable {
    typealias ReturnType = Double
    var functionJobName: String = "calculateShipping"
    var weight: Double
    var destination: String
}

// Each function can be tested, maintained, and reused independently
