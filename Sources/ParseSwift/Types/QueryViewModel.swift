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
open class QueryViewModel<T: ParseObject>: @preconcurrency QueryObservable, @unchecked Sendable {

	private let resultsLock = NSLock()
	private let countLock = NSLock()
	private let errorLock = NSLock()
	private let queryLock = NSLock()
	private var _results = [Object]() {
		willSet {
			self.objectWillChange.send()
		}
	}
	private var _count: Int = 0 {
		willSet {
			if newValue != _results.count {
				self.objectWillChange.send()
			}
		}
	}
	private var _error: ParseError? {
		willSet {
			if newValue != nil {
				_results.removeAll()
				_count = 0
				self.objectWillChange.send()
			}
		}
	}
	private var _query: Query<T>

	@MainActor
	public var query: Query<T> {
		queryLock.lock()
		defer { queryLock.unlock() }
		return _query
	}

    public typealias Object = T

    /// Updates and notifies when the new results have been retrieved.
	@MainActor
	open var results: [Object] {
		get {
			resultsLock.lock()
			defer { resultsLock.unlock() }
			return _results
		}

		set {
			resultsLock.lock()
			defer { resultsLock.unlock() }
			_results = newValue
			error = nil
			count = newValue.count
		}
    }

    /// Updates and notifies when the count of the results have been retrieved.
	@MainActor
	open var count: Int {
		get {
			countLock.lock()
			defer { countLock.unlock() }
			return _count
		}

		set {
			countLock.lock()
			defer { countLock.unlock() }
			_count = newValue
		}
    }

    /// Updates and notifies when there is an error retrieving the results.
	@MainActor
    open var error: ParseError? {
		get {
			errorLock.lock()
			defer { errorLock.unlock() }
			return _error
		}

		set {
			errorLock.lock()
			defer { errorLock.unlock() }
			_error = newValue
		}
    }

    required public init(query: Query<T>) {
        self._query = query
    }

    open func find(options: API.Options = []) async {
        do {
            self.results = try await query.find(options: options)
        } catch {
            self.error = error as? ParseError ?? ParseError(swift: error)
        }
    }

    open func findAll(batchLimit: Int? = nil,
                      options: API.Options = []) async {
        do {
            self.results = try await query.findAll(batchLimit: batchLimit,
                                                   options: options)
        } catch {
            self.error = error as? ParseError ?? ParseError(swift: error)
        }
    }

    open func first(options: API.Options = []) async {
        do {
            let result = try await query.first(options: options)
            self.results = [result]
        } catch {
            self.error = error as? ParseError ?? ParseError(swift: error)
        }
    }

    open func count(options: API.Options = []) async {
        do {
            self.count = try await query.count(options: options)
        } catch {
            self.error = error as? ParseError ?? ParseError(swift: error)
        }
    }

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
@MainActor
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
