import Foundation
import ParseSwift

// ❌ Bad: Generic, unclear event names
var event1 = ParseAnalytics(name: "event1")
var click = ParseAnalytics(name: "buttonClick")

// ✅ Good: Descriptive, specific event names
var tutorialEvent = ParseAnalytics(name: "tutorialCompleted")
var shareEvent = ParseAnalytics(name: "shareButtonTapped")
var checkoutEvent = ParseAnalytics(name: "checkoutInitiated")

// Use consistent naming convention (camelCase recommended)
var signUpEvent = ParseAnalytics(name: "userSignedUp")
var logInEvent = ParseAnalytics(name: "userLoggedIn")
