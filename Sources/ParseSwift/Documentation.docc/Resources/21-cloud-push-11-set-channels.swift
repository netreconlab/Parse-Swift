import Foundation
import ParseSwift

let channelAlert = ParsePushAppleAlert(body: "Hello from ParseSwift again!")
let channelPayload = ParsePushPayloadApple(alert: channelAlert)
    .incrementBadge()

// Create a ParsePush with just the payload
var push = ParsePush(payload: channelPayload)

// Set the channels to target
push.channels = Set(["newDevices"])
