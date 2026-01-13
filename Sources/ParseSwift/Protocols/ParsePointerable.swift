//
//  ParsePointerable.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/25/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol ParsePointer: Encodable, Sendable {

    var __type: String { get } // swiftlint:disable:this identifier_name

    var className: String { get }

    var objectId: String { get set }
}

extension ParsePointer {
    /**
     Determines if two objects have the same objectId.
     - parameter as: Object to compare.
     - returns: Returns **true** if the other object has the same `objectId` or **false** if unsuccessful.
    */
    func hasSameObjectId(as other: any ParsePointer) -> Bool {
        return other.className == className &&
        other.objectId == objectId
    }
}

public protocol ParsePointerObject: ParsePointer, ParseTypeable, Fetchable {
    associatedtype Object: ParseObject
}

extension ParsePointerObject {

    /**
     Convert a Pointer to its respective `ParseObject`.
     - returns: A `ParseObject` created from this Pointer.
     */
    func toObject() -> Object {
        var object = Object()
        object.objectId = self.objectId
        return object
    }

    /**
     Determines if a `ParseObject` and `Pointer`have the same `objectId`.
     - parameter as: `ParseObject` to compare.
     - returns: Returns **true** if the other object has the same `objectId` or **false** if unsuccessful.
    */
    func hasSameObjectId(as other: Object) -> Bool {
        return other.className == className &&
        other.objectId == objectId
    }

    /**
     Determines if two `Pointer`'s have the same `objectId`.
     - parameter as: `Pointer` to compare.
     - returns: Returns **true** if the other object has the same `objectId` or **false** if unsuccessful.
    */
    func hasSameObjectId(as other: Self) -> Bool {
        return other.className == className &&
        other.objectId == objectId
    }

    /**
     Fetches the `ParseObject` *asynchronously* and executes the given callback block.
     - parameter includeKeys: The name(s) of the key(s) to include. Use `["*"]` to include
     all keys.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<T, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func fetch(includeKeys: [String]? = nil,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping @Sendable (Result<Object, ParseError>) -> Void) {
        Task {
            var options = options
            options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))

            let method = API.Method.GET
            let path = API.Endpoint.object(className: className, objectId: objectId)
            let params: [String: String]? = {
                guard let includeKeys = includeKeys else {
                    return nil
                }
                return ["include": "\(Set(includeKeys))"]
            }()
            let mapper = { @Sendable (data) -> Object in
                try ParseCoding.jsonDecoder().decode(Object.self, from: data)
            }
            await API.NonParseBodyCommand<NoBody, Object>(method: method, path: path, params: params, mapper: mapper)
                .execute(options: options,
                         callbackQueue: callbackQueue,
                         completion: completion)
        }
    }
}

// MARK: Batch Support
public extension Sequence where Element: ParsePointerObject {

    /**
     Fetches a collection of objects all at once *asynchronously* and executes the completion block when done.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<[(Result<Element.Object, ParseError>)], ParseError>)`.
     - warning: The order in which objects are returned are not guaranteed. You should not expect results in
     any particular order.
    */
    func fetchAll(
        includeKeys: [String]? = nil,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping @Sendable (Result<[(Result<Element.Object, ParseError>)], ParseError>) -> Void
    ) {
        let objects = Set(compactMap { $0.toObject() })
        objects.fetchAll(
            includeKeys: includeKeys,
            options: options,
            callbackQueue: callbackQueue,
            completion: completion
        )
    }

}
