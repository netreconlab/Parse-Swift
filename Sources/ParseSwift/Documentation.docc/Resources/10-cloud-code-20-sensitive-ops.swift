import Foundation
import ParseSwift

// Example: Charge a credit card (sensitive operation)
struct ChargeCreditCard: ParseCloudable {
    typealias ReturnType = [String: Any]
    var functionJobName: String = "chargeCreditCard"
    
    var amount: Double
    var currency: String
    
    // Don't pass sensitive card details from the client
    // Instead, use a tokenized payment method or saved card ID
    var paymentMethodId: String
}

// Use Cloud Code to securely process the payment
let charge = ChargeCreditCard(
    amount: 29.99,
    currency: "USD",
    paymentMethodId: "pm_12345"
)

do {
    let result = try await charge.runFunction()
    print("Payment processed: \(result)")
} catch {
    print("Payment failed: \(error)")
}
