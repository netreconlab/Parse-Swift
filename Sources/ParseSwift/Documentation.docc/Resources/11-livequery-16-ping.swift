import Foundation
import ParseSwift

// Ping the LiveQuery server to check connection health
ParseLiveQuery.client?.sendPing { error in
    if let error = error {
        print("Error pinging LiveQuery server: \(error)")
    } else {
        print("Successfully pinged server!")
    }
}
