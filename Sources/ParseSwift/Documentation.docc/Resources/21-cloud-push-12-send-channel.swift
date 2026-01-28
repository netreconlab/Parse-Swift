import Foundation
import ParseSwift

let channelAlert = ParsePushAppleAlert(body: "Hello from ParseSwift again!")
let channelPayload = ParsePushPayloadApple(alert: channelAlert)
    .incrementBadge()

var push = ParsePush(payload: channelPayload)
push.channels = Set(["newDevices"])

// Send the push notification to all channel subscribers
push.send { result in
    switch result {
    case .success(let statusId):
        print("The push was created with id: \"\(statusId)\"")
    case .failure(let error):
        print("Could not create push: \(error)")
    }
}
