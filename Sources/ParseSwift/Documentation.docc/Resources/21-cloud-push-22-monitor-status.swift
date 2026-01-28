import Foundation
import ParseSwift

let alert = ParsePushAppleAlert(body: "Important update")
let payload = ParsePushPayloadApple(alert: alert)
let query = Installation.query(isNotNull(key: "objectId"))
let push = ParsePush(payload: payload, query: query)

// Track the status of your push notifications
push.send { result in
    switch result {
    case .success(let statusId):
        // Monitor delivery status
        push.fetchStatus(statusId) { statusResult in
            switch statusResult {
            case .success(let status):
                // Log status for monitoring
                print("Push sent to \(status.numSent ?? 0) devices")
                if let failed = status.numFailed, failed > 0 {
                    print("Warning: \(failed) failed deliveries")
                }
            case .failure(let error):
                print("Could not fetch status: \(error)")
            }
        }
    case .failure(let error):
        print("Push send failed: \(error)")
    }
}
