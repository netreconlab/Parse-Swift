//
//  QueryObservable.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/3/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)
import Foundation

/**
 This protocol describes the interface for creating a view model for a `Query`.
 You can use this protocol on any custom class of yours, instead of `QueryViewModel`, if it fits your use case better.
 */
@MainActor
public protocol QueryObservable: ObservableObject {

    /// The `ParseObject` associated with this view model.
    associatedtype Object: ParseObject

    /// The query associated with this view model.
    var query: Query<Object> { get }

    /**
     Creates a new view model that can be used to handle updates.
     */
    init(query: Query<Object>)

    /**
      Finds objects *asynchronously* based on the constructed query and updates the view model
     when complete.

      - parameter options: A set of header options sent to the server. Defaults to an empty set.
    */
	@MainActor
    func find(options: API.Options) async

    /**
     Retrieves *asynchronously* a complete list of `ParseObject`'s  that satisfy this query
     and updates the view model when complete.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the amount of items to be batched
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - warning: The items are processed in an unspecified order. The query may not have any sort
     order, and may not use limit or skip.
    */
	@MainActor
    func findAll(batchLimit: Int?,
                 options: API.Options) async

    /**
      Gets an object *asynchronously* and updates the view model when complete.

      - warning: This method mutates the query. It will reset the limit to `1`.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
    */
	@MainActor
    func first(options: API.Options) async

    /**
      Counts objects *synchronously* based on the constructed query and updates the view model
     when complete.

      - parameter options: A set of header options sent to the server. Defaults to an empty set.
    */
	@MainActor
    func count(options: API.Options) async

    /**
      Executes an aggregate query *asynchronously* and updates the view model when complete.
        - requires: `.usePrimaryKey` has to be available. It is recommended to only
        use the primary key in server-side applications where the key is kept secure and not
        exposed to the public.
        - parameter pipeline: A pipeline of stages to process query.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - warning: This has not been tested thoroughly.
    */
	@MainActor
    func aggregate(_ pipeline: [[String: Encodable & Sendable]],
                   options: API.Options) async
}
#endif
