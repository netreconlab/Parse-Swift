import Foundation
import ParseSwift

let alert = ParsePushAppleAlert(body: "Hello from ParseSwift!")
let applePayload = ParsePushPayloadApple(alert: alert)
    .setBadge(1)

let installationQuery = Installation.query(isNotNull(key: "objectId"))
let push = ParsePush(payload: applePayload, query: installationQuery)

// Send the push notification
push.send { result in
    switch result {
    case .success(let statusId):
        print("The push was created with id: \"\(statusId)\"")
    case .failure(let error):
        print("Could not create push: \(error)")
    }
}
