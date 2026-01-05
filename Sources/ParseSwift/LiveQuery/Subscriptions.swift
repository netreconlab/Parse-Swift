//
//  Subscriptions.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/29/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

#if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

actor Subscriptions {
	var currentRequestId = 0
    var current = [RequestId: ParseLiveQuery.SubscriptionRecord]()
    var pending = [(RequestId, ParseLiveQuery.SubscriptionRecord)]()

	func requestIdGenerator() -> RequestId {
		self.currentRequestId += 1
		return RequestId(value: self.currentRequestId)
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

    func isEmpty() -> Bool {
        current.isEmpty
    }

    func getCurrent() -> [RequestId: ParseLiveQuery.SubscriptionRecord] {
        current
    }

    func updateCurrent(_ current: [RequestId: ParseLiveQuery.SubscriptionRecord]) {
        for (url, function) in current {
            self.current[url] = function
        }
    }

    func removeCurrent(_ requestIds: [RequestId]) {
        for requestId in requestIds {
            self.current.removeValue(forKey: requestId)
        }
    }

    func removeAll() {
        self.current.removeAll()
    }
}

// MARK: PendingSubscriptions
extension Subscriptions {

    func isPendingEmpty() -> Bool {
        pending.isEmpty
    }

    func getPending() -> [(RequestId, ParseLiveQuery.SubscriptionRecord)] {
        pending
    }

    func updatePending(_ pending: [(RequestId, ParseLiveQuery.SubscriptionRecord)]) {
        self.pending.append(contentsOf: pending)
    }

    func removePending(_ requestIds: [RequestId]) {
        requestIds.forEach { pendingToRemove in
            pending.removeAll(where: { $0.0 == pendingToRemove })
        }
    }

    func removeAllPending() {
        self.pending.removeAll()
    }
}

#endif
