import Foundation
import ParseSwift

Task {
    // Close the current LiveQuery connection
    await ParseLiveQuery.client?.close()
    print("LiveQuery connection closed")

    // This affects all active subscriptions on this connection
    // To close all LiveQuery connections, use: ParseLiveQuery.client?.closeAll()
}
