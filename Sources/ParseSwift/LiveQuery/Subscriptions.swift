//
//  Subscriptions.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/29/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

#if !os(Linux) && !os(Android) && !os(Windows)
import Foundation

actor Subscriptions {
    let requestIdGenerator: () -> RequestId
    var subscriptions = [RequestId: ParseLiveQuery.SubscriptionRecord]()
    var pendingSubscriptions = [(RequestId, ParseLiveQuery.SubscriptionRecord)]()

    init() {
        // Simple incrementing generator
        var currentRequestId = 0
        requestIdGenerator = {
            currentRequestId += 1
            return RequestId(value: currentRequestId)
        }
    }
}

// MARK: RequestIdGenerator
extension Subscriptions {
    func getRequestId() -> RequestId {
        requestIdGenerator()
    }
}

// MARK: Subscriptions
extension Subscriptions {

    func isSubscriptionsEmpty() -> Bool {
        subscriptions.isEmpty
    }

    func getSubscriptions() -> [RequestId: ParseLiveQuery.SubscriptionRecord] {
        subscriptions
    }

    func updateSubscriptions(_ subscriptions: [RequestId: ParseLiveQuery.SubscriptionRecord]) {
        for (url, function) in subscriptions {
            self.subscriptions[url] = function
        }
    }

    func removeSubscriptions(_ requestIds: [RequestId]) {
        for requestId in requestIds {
            self.subscriptions.removeValue(forKey: requestId)
        }
    }

    func removeAllSubscriptions() {
        self.subscriptions.removeAll()
    }
}

// MARK: PendingSubscriptions
extension Subscriptions {

    func isPendingSubscriptionsEmpty() -> Bool {
        pendingSubscriptions.isEmpty
    }

    func getPendingSubscriptions() -> [(RequestId, ParseLiveQuery.SubscriptionRecord)] {
        pendingSubscriptions
    }

    func updatePendingSubscriptions(_ pendingSubscriptions: [(RequestId, ParseLiveQuery.SubscriptionRecord)]) {
        self.pendingSubscriptions.append(contentsOf: pendingSubscriptions)
    }

    func removePendingSubscriptions(_ pendingSubscriptionsRequestIds: [RequestId]) {
        pendingSubscriptionsRequestIds.forEach { pendingToRemove in
            pendingSubscriptions.removeAll(where: { $0.0 == pendingToRemove })
        }
    }

    func removeAllPendingSubscriptions() {
        self.pendingSubscriptions.removeAll()
    }
}

#endif
