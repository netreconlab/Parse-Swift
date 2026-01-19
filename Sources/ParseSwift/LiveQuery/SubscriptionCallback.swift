//
//  SubscriptionCallback.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/24/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/**
 A default implementation of the `QuerySubscribable` protocol using closures for callbacks.
 */
open class SubscriptionCallback<T: ParseObject>: QuerySubscribable, @unchecked Sendable {

	private let lock = NSLock()
	private let eventLock = NSLock()
	private let subscribedLock = NSLock()
	private let unsubscribedLock = NSLock()
	private var _query: Query<T>
	fileprivate var eventHandlers: [(Query<T>, Event<T>) -> Void] {
		get {
			eventLock.lock()
			defer { eventLock.unlock() }
			return _eventHandlers
		}
		set {
			eventLock.lock()
			defer { eventLock.unlock() }
			_eventHandlers = newValue
		}
	}
	fileprivate var subscribeHandlers: [(Query<T>, Bool) -> Void] {
		get {
			subscribedLock.lock()
			defer { subscribedLock.unlock() }
			return _subscribeHandlers
		}
		set {
			subscribedLock.lock()
			defer { subscribedLock.unlock() }
			_subscribeHandlers = newValue
		}
	}
	fileprivate var unsubscribeHandlers: [(Query<T>) -> Void] {
		get {
			unsubscribedLock.lock()
			defer { unsubscribedLock.unlock() }
			return _unsubscribeHandlers
		}
		set {
			unsubscribedLock.lock()
			defer { unsubscribedLock.unlock() }
			_unsubscribeHandlers = newValue
		}
	}

	fileprivate var _eventHandlers = [(Query<T>, Event<T>) -> Void]()
	fileprivate var _subscribeHandlers = [(Query<T>, Bool) -> Void]()
	fileprivate var _unsubscribeHandlers = [(Query<T>) -> Void]()

	public var query: Query<T> {
		get {
			lock.lock()
			defer { lock.unlock() }
			return _query
		}
		set {
			lock.lock()
			defer { lock.unlock() }
			_query = newValue
		}
	}

    public typealias Object = T

    /**
     Creates a new subscription that can be used to handle updates.
     */
    public required init(query: Query<T>) {
        self._query = query
    }

    /**
     Register a callback for when an event occurs.
     - parameter handler: The callback to register.
     - returns: The same subscription, for easy chaining.
     */
    @discardableResult open func handleEvent(
		_ handler: @escaping @Sendable (Query<T>, Event<T>) -> Void
	) -> SubscriptionCallback {
        eventHandlers.append(handler)
        return self
    }

    /**
     Register a callback for when a client successfully subscribes to a query.
     - parameter handler: The callback to register.
     - returns: The same subscription, for easy chaining.
     */
    @discardableResult open func handleSubscribe(
		_ handler: @escaping  @Sendable (Query<T>, Bool) -> Void
	) -> SubscriptionCallback {
        subscribeHandlers.append(handler)
        return self
    }

    /**
     Register a callback for when a query has been unsubscribed.
     - parameter handler: The callback to register.
     - returns: The same subscription, for easy chaining.
     */
    @discardableResult open func handleUnsubscribe(
		_ handler: @escaping @Sendable (Query<T>) -> Void
	) -> SubscriptionCallback {
        unsubscribeHandlers.append(handler)
        return self
    }

    /**
     Register a callback for when an event occurs of a specific type
     Example:
         subscription.handle(Event.Created) { query, object in
            // Called whenever an object is creaated
         }
     - parameter eventType: The event type to handle. You should pass one of the enum cases in `Event`.
     - parameter handler: The callback to register.
     - returns: The same subscription, for easy chaining.
     */
    @discardableResult public func handle(
		_ eventType: @escaping @Sendable (T) -> Event<T>,
		_ handler: @escaping @Sendable (Query<T>, T) -> Void
	) -> SubscriptionCallback {
        return handleEvent { query, event in
            switch event {
            case .entered(let obj) where eventType(obj) == event: handler(query, obj)
            case .left(let obj)  where eventType(obj) == event: handler(query, obj)
            case .created(let obj) where eventType(obj) == event: handler(query, obj)
            case .updated(let obj) where eventType(obj) == event: handler(query, obj)
            case .deleted(let obj) where eventType(obj) == event: handler(query, obj)
            default: return
            }
        }
    }

    // MARK: QuerySubscribable

    open func didReceive(
		_ eventData: Data
	) throws {
        // Need to decode the event with respect to the `ParseObject`.
        let eventMessage = try ParseCoding.jsonDecoder().decode(EventResponse<T>.self, from: eventData)
        guard let event = Event(event: eventMessage) else {
            throw ParseError(code: .otherCause, message: "ParseLiveQuery Error: Could not create event.")
        }
        eventHandlers.forEach { $0(query, event) }
    }

    open func didSubscribe(
		_ new: Bool
	) {
        subscribeHandlers.forEach { $0(query, new) }
    }

    open func didUnsubscribe() {
        unsubscribeHandlers.forEach { $0(query) }
    }
}
