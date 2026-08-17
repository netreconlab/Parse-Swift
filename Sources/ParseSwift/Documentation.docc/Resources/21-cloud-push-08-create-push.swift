import Foundation
import ParseSwift

let alert = ParsePushAppleAlert(body: "Hello from ParseSwift!")
let applePayload = ParsePushPayloadApple(alert: alert)
    .setBadge(1)

let installationQuery = Installation.query(isNotNull(key: "objectId"))

// Create a ParsePush instance with the payload and query
let push = ParsePush(payload: applePayload, query: installationQuery)
