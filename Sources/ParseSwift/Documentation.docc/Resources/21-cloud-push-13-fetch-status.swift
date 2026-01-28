import Foundation
import ParseSwift

let push = ParsePush(payload: applePayload, query: installationQuery)
var pushStatusId = ""

push.send { result in
    switch result {
    case .success(let statusId):
        pushStatusId = statusId
    case .failure(let error):
        print("Could not create push: \(error)")
    }
}

// Fetch the status of the notification
push.fetchStatus(pushStatusId) { result in
    switch result {
    case .success(let pushStatus):
        print("The push status is: \"\(pushStatus)\"")
    case .failure(let error):
        print("Could not fetch push status: \(error)")
    }
}
