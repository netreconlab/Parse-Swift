import Foundation
import ParseSwift

Task {
    // Close the current LiveQuery connection
    await ParseLiveQuery.client?.close()
    print("LiveQuery connection closed")
    
    // This affects all active subscriptions on this connection
    // To close all LiveQuery connections, use: ParseLiveQuery.client?.closeAll()
}

// Ping the LiveQuery server - this should produce an error
// because LiveQuery is disconnected
ParseLiveQuery.client?.sendPing { error in
    if let error = error {
        print("Error pinging LiveQuery server: \(error)")
    } else {
        print("Successfully pinged server!")
    }
}
