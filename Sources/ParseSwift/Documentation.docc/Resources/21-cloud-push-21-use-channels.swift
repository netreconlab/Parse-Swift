import Foundation
import ParseSwift

// SERVER-SIDE: Send targeted notifications to specific channels
// WARNING: This requires the primary key and must run in a trusted server environment
// Do NOT run this in your client app - use Cloud Code or Parse-Server-Swift/Vapor

// Note: Users subscribe to channels in your client app by awaiting Installation.current()
// and then saving the installation (see Installation tutorial for client-side channel subscription)
// This server-side code targets those subscribed users by channel name

let alert = ParsePushAppleAlert(body: "Breaking sports news!")
let payload = ParsePushPayloadApple(alert: alert)

var push = ParsePush(payload: payload)
push.channels = Set(["sports"])

Task {
    do {
        try await push.send()
        print("Push sent to sports channel")
    } catch {
        print("Error sending push: \(error)")
    }
}
