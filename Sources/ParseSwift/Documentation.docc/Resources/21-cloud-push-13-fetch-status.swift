import Foundation
import ParseSwift

let alert = ParsePushAppleAlert(body: "Hello from ParseSwift!")
let applePayload = ParsePushPayloadApple(alert: alert)
    .setBadge(1)

let installationQuery = Installation.query(isNotNull(key: "objectId"))
let push = ParsePush(payload: applePayload, query: installationQuery)

push.send { result in
    switch result {
    case .success(let statusId):
        // Fetch the status of the notification after successfully sending the push
        push.fetchStatus(statusId) { result in
            switch result {
            case .success(let pushStatus):
                print("The push status is: \"\(pushStatus)\"")
            case .failure(let error):
                print("Could not fetch push status: \(error)")
            }
        }
    case .failure(let error):
        print("Could not create push: \(error)")
    }
}
