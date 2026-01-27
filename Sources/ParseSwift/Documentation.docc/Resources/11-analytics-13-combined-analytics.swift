import Foundation
import ParseSwift

// Combine descriptive event names with relevant dimensions
var purchaseEvent = ParseAnalytics(name: "purchaseCompleted")

try await purchaseEvent.track(dimensions: [
    "productCategory": "books",
    "priceRange": "10-20",
    "paymentMethod": "creditCard",
    "isFirstPurchase": "true"
])

// This creates a rich analytics record that can answer questions like:
// - What categories are most popular?
// - What price ranges sell best?
// - How do payment methods affect conversion?
// - How many purchases are from new vs. returning customers?
