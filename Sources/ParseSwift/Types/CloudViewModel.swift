//
//  CloudViewModel.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/11/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//
#if canImport(Combine)
import Foundation
import Combine

/**
 A default implementation of the `CloudCodeObservable` protocol. Suitable for `ObjectObserved`
 and can be used as a SwiftUI view model. Also can be used as a Combine publisher. See Apple's
 [documentation](https://developer.apple.com/documentation/combine/observableobject)
 for more details.
 */
open class CloudViewModel<T: ParseCloudable>: CloudObservable, @unchecked Sendable {

	private let resultsLock = NSLock()
	private let cloudCodeLock = NSLock()
	private let errorLock = NSLock()
	private var _results: T.ReturnType? {
		willSet {
			if newValue != nil {
				self.objectWillChange.send()
			}
		}
	}
	private var _cloudCode: T
	private var _error: ParseError? {
		willSet {
			if newValue != nil {
				_results = nil
				self.objectWillChange.send()
			}
		}
	}

	public typealias CloudCodeType = T
	public var cloudCode: T {
		get {
			cloudCodeLock.lock()
			defer { cloudCodeLock.unlock() }
			return _cloudCode
		}

		set {
			cloudCodeLock.lock()
			defer { cloudCodeLock.unlock() }
			_cloudCode = newValue
		}
	}

    /// Updates and notifies when the new results have been retrieved.
    open var results: T.ReturnType? {
		get {
			resultsLock.lock()
			defer { resultsLock.unlock() }
			return _results
		}

		set {
			resultsLock.lock()
			defer { resultsLock.unlock() }
			error = nil
			_results = newValue
		}
    }

    /// Updates and notifies when there is an error retrieving the results.
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

    required public init(cloudCode: T) {
        self._cloudCode = cloudCode
    }

    public func runFunction(options: API.Options = []) async {
        do {
            self.results = try await cloudCode.runFunction(options: options)
        } catch {
            self.error = error as? ParseError ?? ParseError(swift: error)
        }
    }

    public func startJob(options: API.Options = []) async {
        do {
            self.results = try await cloudCode.startJob(options: options)
        } catch {
            self.error = error as? ParseError ?? ParseError(swift: error)
        }
    }
}

// MARK: CloudCodeViewModel
@MainActor
public extension ParseCloudable {

    /**
     Creates a view model for this CloudCode. Suitable for `ObjectObserved`
     as the view model can be used as a SwiftUI publisher. Meaning it can serve
     indepedently as a ViewModel in MVVM.
     */

	var viewModel: CloudViewModel<Self> {
        CloudViewModel(cloudCode: self)
    }

    /**
     Creates a view model for this CloudCode. Suitable for `ObjectObserved`
     as the view model can be used as a SwiftUI publisher. Meaning it can serve
     indepedently as a ViewModel in MVVM.
     - parameter query: Any query.
     - returns: The view model for this query.
     */
	static func viewModel(_ cloudCode: Self) -> CloudViewModel<Self> {
        CloudViewModel(cloudCode: cloudCode)
    }
}
#endif
