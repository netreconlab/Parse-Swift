import Foundation
import ParseSwift

// Create a delegate for LiveQuery errors and connection events
final class LiveQueryDelegate: NSObject, ParseLiveQueryDelegate {

    func received(_ error: Error) {
        print("LiveQuery error: \(error)")
    }

    func closedSocket(_ code: URLSessionWebSocketTask.CloseCode?, reason: Data?) {
        print("Socket closed with code: \(String(describing: code))")
        print("Reason: \(String(describing: reason))")
    }
}

// Set the delegate on the default LiveQuery client
let delegate = LiveQueryDelegate()
if let client = ParseLiveQuery.defaultClient {
    client.receiveDelegate = delegate
    print("LiveQuery delegate set successfully")
} else {
    print("Warning: LiveQuery default client not available")
}
