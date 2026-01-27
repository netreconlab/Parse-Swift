import Foundation
import ParseSwift

// Create a custom analytics event with a descriptive name
var friendEvent = ParseAnalytics(name: "openedFriendList")

// Or create other events for different user actions
var tutorialEvent = ParseAnalytics(name: "completedTutorial")
var purchaseEvent = ParseAnalytics(name: "purchaseCompleted")
