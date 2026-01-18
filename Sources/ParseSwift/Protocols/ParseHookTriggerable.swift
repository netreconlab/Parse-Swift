//
//  ParseHookTriggerable.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/14/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/**
 Conforming to `ParseHookTriggerable` allows the creation of hooks which
 are Cloud Code triggers.
 - requires: `.usePrimaryKey` has to be available. It is recommended to only
 use the primary key in server-side applications where the key is kept secure and not
 exposed to the public.
 */
public protocol ParseHookTriggerable: ParseHookable {
    /// The name of the `ParseObject` the trigger should act on.
    var className: String? { get set }
    /// The `ParseHookTriggerType` type.
    var trigger: ParseHookTriggerType? { get set }
}

// MARK: Default Implementation
public extension ParseHookTriggerable {

    /**
     Creates a new Parse hook trigger.
     - parameter className: The name of the `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter url: The endpoint of the hook.
     */
    init(
        className: String,
        trigger: ParseHookTriggerType,
        url: URL
    ) {
        self.init()
        self.className = className
        self.trigger = trigger
        self.url = url
    }

    /**
     Creates a new Parse hook trigger.
     - parameter object: The `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter url: The endpoint of the hook.
     */
    init<T>(
        object: T.Type,
        trigger: ParseHookTriggerType,
        url: URL
    ) where T: ParseObject {
        self.init(className: object.className, trigger: trigger, url: url)
    }

    /**
     Creates a new Parse hook trigger.
     - parameter object: The `ParseObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter url: The endpoint of the hook.
     */
    init<T>(
        object: T,
        trigger: ParseHookTriggerType,
        url: URL
    ) where T: ParseObject {
        self.init(className: T.className, trigger: trigger, url: url)
    }

    /**
     Creates a new Parse hook trigger for any supported `ParseHookTriggerObject`.
     - parameter object: The `ParseHookTriggerObject` the trigger should act on.
     - parameter trigger: The `ParseHookTriggerType` type.
     - parameter url: The endpoint of the hook.
     */
    init( // swiftlint:disable:this cyclomatic_complexity function_body_length
        object: ParseHookTriggerObject,
        trigger: ParseHookTriggerType,
        url: URL
    ) throws {

        let notSupportedError = ParseError(
            code: .otherCause,
            message: "This object \"\(object)\" currently does not support the hook trigger \"\(trigger)\""
        )

        switch object {
        case .objectType(let parseObject):
            switch trigger {
			case .beforeLogin, .afterLogin, .afterLogout, .beforePasswordResetRequest:
                guard parseObject is (any ParseUser.Type) else {
                    throw notSupportedError
                }
            case .beforeSave, .afterSave, .beforeDelete,
                    .afterDelete, .beforeFind, .afterFind,
                    .beforeSubscribe, .afterEvent:
                break // No op
            default:
                throw notSupportedError
            }
            self.init(
                className: object.className,
                trigger: trigger,
                url: url
            )
        case .object(let parseObject):
            switch trigger {
			case .beforeLogin, .afterLogin, .afterLogout, .beforePasswordResetRequest:
                guard parseObject is (any ParseUser) else {
                    throw notSupportedError
                }
            case .beforeSave, .afterSave, .beforeDelete,
                    .afterDelete, .beforeFind, .afterFind,
                    .beforeSubscribe, .afterEvent:
                break // No op
            default:
                throw notSupportedError
            }
            self.init(
                className: object.className,
                trigger: trigger,
                url: url
            )
        case .file:
            switch trigger {
            case .beforeSave, .afterSave, .beforeDelete,
					.afterDelete, .beforeFind, .afterFind:
                break // No op
            default:
                throw notSupportedError
            }
            self.init(
                className: object.className,
                trigger: trigger,
                url: url
            )
        case .config:
            switch trigger {
            case .beforeSave, .afterSave:
                break // No op
            default:
                throw notSupportedError
            }
            self.init(
                className: object.className,
                trigger: trigger,
                url: url
            )
        case .liveQueryConnect:
            guard trigger == .beforeConnect else {
                throw notSupportedError
            }
            self.init(
                className: object.className,
                trigger: trigger,
                url: url
            )
        }
    }
}

/// A type of request for Parse Hook Triggers.
public struct TriggerRequest: Encodable, Sendable {
    let className: String
    let trigger: ParseHookTriggerType
    let url: URL?

    /**
     Creates an instance.
     - parameter trigger: A type that conforms to `ParseHookTriggerable`.
     - throws: An error of `ParseError` type.
     */
    public init<T>(trigger: T) throws where T: ParseHookTriggerable {
        guard let className = trigger.className,
              let triggerType = trigger.trigger else {
            throw ParseError(code: .otherCause,
                             message: "The \"className\" and \"trigger\" needs to be set: \(trigger)")
        }
        self.className = className
        self.trigger = triggerType
        self.url = trigger.url
    }

    enum CodingKeys: String, CodingKey {
        case className
        case trigger = "triggerName"
        case url
    }
}

// MARK: Fetch
extension ParseHookTriggerable {
    /**
     Fetches the Parse hook trigger *asynchronously* and executes the given callback block.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func fetch(options: API.Options = [],
                      callbackQueue: DispatchQueue = .main,
                      completion: @escaping @Sendable (Result<Self, ParseError>) -> Void) {
        Task {
            var options = options
            options.insert(.usePrimaryKey)
            options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
            do {
                try await fetchCommand().execute(options: options,
                                                 callbackQueue: callbackQueue,
                                                 completion: completion)
            } catch {
                let parseError = error as? ParseError ?? ParseError(swift: error)
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
    }

    func fetchCommand() throws -> API.NonParseBodyCommand<Self, Self> {
        let request = try TriggerRequest(trigger: self)
        return API.NonParseBodyCommand(method: .GET,
                                       path: .hookTrigger(request: request)) { (data) -> Self in
            try ParseCoding.jsonDecoder().decode(Self.self, from: data)
        }
    }

    /**
     Fetches all of the Parse hook triggers *asynchronously* and executes the given callback block.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func fetchAll(options: API.Options = [],
                         callbackQueue: DispatchQueue = .main,
                         completion: @escaping @Sendable (Result<[Self], ParseError>) -> Void) {
        Self.fetchAll(options: options,
                      callbackQueue: callbackQueue,
                      completion: completion)
    }

    /**
     Fetches all of the Parse hook triggers *asynchronously* and executes the given callback block.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public static func fetchAll(options: API.Options = [],
                                callbackQueue: DispatchQueue = .main,
                                completion: @escaping @Sendable (Result<[Self], ParseError>) -> Void) {
        Task {
            var options = options
            options.insert(.usePrimaryKey)
            options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
            await fetchAllCommand().execute(options: options,
                                            callbackQueue: callbackQueue,
                                            completion: completion)
        }
    }

    static func fetchAllCommand() -> API.NonParseBodyCommand<Self, [Self]> {
        API.NonParseBodyCommand(method: .GET,
                                path: .hookTriggers) { (data) -> [Self] in
            try ParseCoding.jsonDecoder().decode([Self].self, from: data)
        }
    }
}

// MARK: Create
extension ParseHookTriggerable {
    /**
     Creates the Parse hook trigger *asynchronously* and executes the given callback block.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func create(options: API.Options = [],
                       callbackQueue: DispatchQueue = .main,
                       completion: @escaping @Sendable (Result<Self, ParseError>) -> Void) {
        Task {
            var options = options
            options.insert(.usePrimaryKey)
            options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
            do {
                try await createCommand().execute(options: options,
                                                  callbackQueue: callbackQueue,
                                                  completion: completion)
            } catch {
                let parseError = error as? ParseError ?? ParseError(swift: error)
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
    }

    func createCommand() throws -> API.NonParseBodyCommand<TriggerRequest, Self> {
        let request = try TriggerRequest(trigger: self)
        return API.NonParseBodyCommand(method: .POST,
                                       path: .hookTriggers,
                                       body: request) { (data) -> Self in
            try ParseCoding.jsonDecoder().decode(Self.self, from: data)
        }
    }
}

// MARK: Update
extension ParseHookTriggerable {
    /**
     Fetches the Parse hook trigger *asynchronously* and executes the given callback block.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func update(options: API.Options = [],
                       callbackQueue: DispatchQueue = .main,
                       completion: @escaping @Sendable (Result<Self, ParseError>) -> Void) {
        Task {
            var options = options
            options.insert(.usePrimaryKey)
            options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
            do {
                try await updateCommand().execute(options: options,
                                                  callbackQueue: callbackQueue,
                                                  completion: completion)
            } catch {
                let parseError = error as? ParseError ?? ParseError(swift: error)
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
    }

    func updateCommand() throws -> API.NonParseBodyCommand<TriggerRequest, Self> {
        let request = try TriggerRequest(trigger: self)
        return API.NonParseBodyCommand(method: .PUT,
                                       path: .hookTrigger(request: request),
                                       body: request) { (data) -> Self in
            try ParseCoding.jsonDecoder().decode(Self.self, from: data)
        }
    }
}

// MARK: Delete
extension ParseHookTriggerable {
    /**
     Deletes the Parse hook trigger *asynchronously* and executes the given callback block.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Void, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func delete(options: API.Options = [],
                       callbackQueue: DispatchQueue = .main,
                       completion: @escaping @Sendable (Result<Void, ParseError>) -> Void) {
        Task {
            var options = options
            options.insert(.usePrimaryKey)
            options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
            do {
                try await deleteCommand().execute(options: options,
                                                  callbackQueue: callbackQueue) { result in
                    switch result {

                    case .success:
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            } catch {
                let parseError = error as? ParseError ?? ParseError(swift: error)
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
    }

    func deleteCommand() throws -> API.NonParseBodyCommand<ParseOperationDelete, NoBody> {
        let request = try TriggerRequest(trigger: self)
        return API.NonParseBodyCommand(method: .PUT,
                                       path: .hookTrigger(request: request),
                                       body: ParseOperationDelete()) { (data) -> NoBody in
            try ParseCoding.jsonDecoder().decode(NoBody.self, from: data)
        }
    }
}
