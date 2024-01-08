//
//  ParsePointerable.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/25/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

protocol ParsePointer: Encodable {

    var __type: String { get } // swiftlint:disable:this identifier_name

    var className: String { get }

    var objectId: String { get set }
}

extension ParsePointer {
    /**
     Determines if two objects have the same objectId.
     - parameter as: Object to compare.
     - returns: Returns a **true** if the other object has the same `objectId` or **false** if unsuccessful.
    */
    func hasSameObjectId(as other: any ParsePointer) -> Bool {
        return other.className == className && other.objectId == objectId
    }
}

protocol ParsePointerObject: ParsePointer, ParseTypeable, Fetchable, Hashable {
    associatedtype Object: ParseObject
}

extension ParsePointerObject {

    /**
     Determines if a `ParseObject` and `Pointer`have the same `objectId`.
     - parameter as: `ParseObject` to compare.
     - returns: Returns a **true** if the other object has the same `objectId` or **false** if unsuccessful.
    */
    func hasSameObjectId(as other: Object) -> Bool {
        return other.className == className && other.objectId == objectId
    }

    /**
     Determines if two `Pointer`'s have the same `objectId`.
     - parameter as: `Pointer` to compare.
     - returns: Returns a **true** if the other object has the same `objectId` or **false** if unsuccessful.
    */
    func hasSameObjectId(as other: Self) -> Bool {
        return other.className == className && other.objectId == objectId
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
               completion: @escaping (Result<Object, ParseError>) -> Void) {
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
            let mapper = { (data) -> Object in
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
extension Sequence where Element: ParsePointerObject {

}
