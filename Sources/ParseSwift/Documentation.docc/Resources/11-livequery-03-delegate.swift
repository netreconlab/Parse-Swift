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
