//
//  QueryViewModel.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/3/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

/**
 A default implementation of the `QueryObservable` protocol. Suitable for `ObjectObserved`
 and can be used as a SwiftUI view model. Also can be used as a Combine publisher. See Apple's
 [documentation](https://developer.apple.com/documentation/combine/observableobject)
 for more details.
 */
open class QueryViewModel<T: ParseObject>: QueryObservable {

    public var query: Query<T>
    public typealias Object = T

    /// Updates and notifies when the new results have been retrieved.
    open var results = [Object]() {
        willSet {
            count = newValue.count
            self.objectWillChange.send()
        }
    }

    /// Updates and notifies when the count of the results have been retrieved.
    open var count = 0 {
        willSet {
            error = nil
            if newValue != results.count {
                self.objectWillChange.send()
            }
        }
    }

    /// Updates and notifies when there is an error retrieving the results.
    open var error: ParseError? {
        willSet {
            if newValue != nil {
                results.removeAll()
                count = results.count
                self.objectWillChange.send()
            }
        }
    }

    required public init(query: Query<T>) {
        self.query = query
    }

    @MainActor
    open func find(options: API.Options = []) async {
        do {
            self.results = try await query.find(options: options)
        } catch {
            self.error = error as? ParseError ?? ParseError(swift: error)
        }
    }

    @MainActor
    open func findAll(batchLimit: Int? = nil,
                      options: API.Options = []) async {
        do {
            self.results = try await query.findAll(batchLimit: batchLimit,
                                                   options: options)
        } catch {
            self.error = error as? ParseError ?? ParseError(swift: error)
        }
    }

    @MainActor
    open func first(options: API.Options = []) async {
        do {
            let result = try await query.first(options: options)
            self.results = [result]
        } catch {
            self.error = error as? ParseError ?? ParseError(swift: error)
        }
    }

    @MainActor
    open func count(options: API.Options = []) async {
        do {
            self.count = try await query.count(options: options)
        } catch {
            self.error = error as? ParseError ?? ParseError(swift: error)
        }
    }

    @MainActor
    open func aggregate(_ pipeline: [[String: Encodable & Sendable]],
                        options: API.Options = []) async {
        do {
            self.results = try await query.aggregate(pipeline, options: options)
        } catch {
            self.error = error as? ParseError ?? ParseError(swift: error)
        }
    }
}

// MARK: QueryViewModel
public extension Query {

    /**
     Creates a view model for this query. Suitable for `ObjectObserved`
     as the view model can be used as a SwiftUI publisher. Meaning it can serve
     indepedently as a ViewModel in MVVM.
     */
    var viewModel: QueryViewModel<ResultType> {
        QueryViewModel(query: self)
    }

    /**
     Creates a view model for this query. Suitable for `ObjectObserved`
     as the view model can be used as a SwiftUI publisher. Meaning it can serve
     indepedently as a ViewModel in MVVM.
     - parameter query: Any query.
     - returns: The view model for this query.
     */
    static func viewModel(_ query: Self) -> QueryViewModel<ResultType> {
        QueryViewModel(query: query)
    }
}
#endif
