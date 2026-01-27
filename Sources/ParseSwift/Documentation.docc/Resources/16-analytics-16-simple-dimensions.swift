import Foundation
import ParseSwift

// ❌ Bad: Too many dimensions, PII included, inconsistent keys
var badEvent = ParseAnalytics(name: "userAction")
badEvent.track(dimensions: [
    "user_email": "user@example.com",  // Don't include PII!
    "user_name": "John Doe",            // Don't include PII!
    "timestamp_long": "1234567890123",
    "very_long_description": "A very long string...",
    "screen": "home",
    "Screen": "Home"  // Inconsistent capitalization
]) { _ in }

// ✅ Good: Limited, consistent, categorical dimensions
var goodEvent = ParseAnalytics(name: "featureUsed")
goodEvent.track(dimensions: [
    "featureName": "imageFilter",
    "filterType": "vintage",
    "source": "homeScreen"
]) { _ in }
