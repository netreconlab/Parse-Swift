//
//  ParseAnalytics.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/20/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if os(iOS)
import UIKit
#endif

/**
 `ParseAnalytics` provides an interface to Parse's logging and analytics backend.
 */
public struct ParseAnalytics: ParseTypeable {

    /// The name of the custom event to report to Parse as having happened.
    public var name: String

    /// Explicitly set the time associated with a given event. If not provided the server
    /// time will be used.
    public var date: Date?

    /// The dictionary of information by which to segment this event.
    public var dimensions: [String: Codable]? {
        get {
            convertToString(dimensionsAnyCodable)
        }
        set {
            dimensionsAnyCodable = convertToAnyCodable(newValue)
        }
    }

    var dimensionsAnyCodable: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case date = "at"
        case dimensions
        case name
    }

    /**
     Create an instance of ParseAnalytics for tracking.
     - parameter name: The name of the custom event to report to Parse as having happened.
     - parameter dimensions: The dictionary of information by which to segment this event. Defaults to `nil`.
     - parameter at: Explicitly set the time associated with a given event. If not provided the server
     time will be used. Defaults to `nil`.
     */
    public init (name: String,
                 dimensions: [String: Codable]? = nil,
                 at date: Date? = nil) {
        self.name = name
        self.dimensionsAnyCodable = convertToAnyCodable(dimensions)
        self.date = date
    }

    // MARK: Helpers
    func convertToAnyCodable(_ dimensions: [String: Codable]?) -> [String: AnyCodable]? {
        guard let dimensions = dimensions else {
            return nil
        }
        var convertedDimensions = [String: AnyCodable]()
        for (key, value) in dimensions {
            convertedDimensions[key] = AnyCodable(value)
        }
        return convertedDimensions
    }

    func convertToString(_ dimensions: [String: AnyCodable]?) -> [String: String]? {
        guard let dimensions = dimensions else {
            return nil
        }
        var convertedDimensions = [String: String]()
        for (key, value) in dimensions {
            convertedDimensions[key] = "\(value.value)"
        }
        return convertedDimensions
    }

    // MARK: Intents

    #if os(iOS)

    /**
     Tracks *asynchronously* this application being launched. If this happened as the result of the
     user opening a push notification, this method sends along information to
     correlate this open with that push.
     
     - parameter launchOptions: The dictionary indicating the reason the application was
     launched, if any. This value can be found as a parameter to various
     `UIApplicationDelegate` methods, and can be empty or `nil`.
     - parameter at: Explicitly set the time associated with a given event. If not provided the
     server time will be used.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: A block that will be called when file deletes or fails.
     It should have the following argument signature: `(Result<Void, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    static public func trackAppOpened(launchOptions: [UIApplication.LaunchOptionsKey: Any],
                                      at date: Date? = nil,
                                      options: API.Options = [],
                                      callbackQueue: DispatchQueue = .main,
                                      completion: @escaping (Result<Void, ParseError>) -> Void) {
        Task {
            var options = options
            options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
            var userInfo = [String: String]()
            launchOptions.forEach { (key, value) in
                guard let value = value as? String else {
                    return
                }
                userInfo[key.rawValue] = value
            }
            let appOppened = ParseAnalytics(name: "AppOpened",
                                            dimensions: userInfo,
                                            at: date)
            await appOppened.saveCommand().execute(options: options,
                                                   callbackQueue: callbackQueue) { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    #endif

    /**
     Tracks *asynchronously* this application being launched with additional dimensions.
     
     - parameter dimensions: The dictionary of information by which to segment this
     event. Can be empty or `nil`.
     - parameter at: Explicitly set the time associated with a given event. If not provided the
     server time will be used.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: A block that will be called when file deletes or fails.
     It should have the following argument signature: `(Result<Void, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    static public func trackAppOpened(dimensions: [String: String]? = nil,
                                      at date: Date? = nil,
                                      options: API.Options = [],
                                      callbackQueue: DispatchQueue = .main,
                                      completion: @escaping (Result<Void, ParseError>) -> Void) {
        Task {
            var options = options
            options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
            let appOppened = ParseAnalytics(name: "AppOpened",
                                            dimensions: dimensions,
                                            at: date)
            await appOppened.saveCommand().execute(options: options,
                                                   callbackQueue: callbackQueue) { result in
                callbackQueue.async {
                    switch result {
                    case .success:
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    /**
     Tracks *asynchronously* the occurrence of a custom event.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: A block that will be called when file deletes or fails.
     It should have the following argument signature: `(Result<Void, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func track(options: API.Options = [],
                      callbackQueue: DispatchQueue = .main,
                      completion: @escaping (Result<Void, ParseError>) -> Void) {
        Task {
            var options = options
            options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
            await self.saveCommand().execute(options: options,
                                             callbackQueue: callbackQueue) { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    /**
     Tracks *asynchronously* the occurrence of a custom event with additional dimensions.
     
     - parameter dimensions: The dictionary of information by which to segment this
     event. Can be empty or `nil`.
     - parameter at: Explicitly set the time associated with a given event. If not provided the
     server time will be used.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: A block that will be called when file deletes or fails.
     It should have the following argument signature: `(Result<Void, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public mutating func track(dimensions: [String: String]?,
                               at date: Date? = nil,
                               options: API.Options = [],
                               callbackQueue: DispatchQueue = .main,
                               completion: @escaping (Result<Void, ParseError>) -> Void) {

        var mutableOptions = options
        mutableOptions.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        self.dimensionsAnyCodable = convertToAnyCodable(dimensions)
        self.date = date
        let options = mutableOptions
        let immutableSelf = self
        Task {
            await immutableSelf.saveCommand().execute(options: options,
                                                      callbackQueue: callbackQueue) { result in
                callbackQueue.async {
                    switch result {
                    case .success:
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    internal func saveCommand() -> API.NonParseBodyCommand<Self, NoBody> {
        return API.NonParseBodyCommand(method: .POST,
                                       path: .event(event: name),
                                       body: self) { (data) -> NoBody in
            let parseError: ParseError!
            do {
                parseError = try ParseCoding.jsonDecoder().decode(ParseError.self, from: data)
            } catch {
                return try ParseCoding.jsonDecoder().decode(NoBody.self, from: data)
            }
            throw parseError
        }
    }
}

// MARK: Codable
public extension ParseAnalytics {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        date = try values.decodeIfPresent(Date.self, forKey: .date)
        dimensionsAnyCodable = try values.decodeIfPresent([String: AnyCodable].self, forKey: .dimensions)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(date, forKey: .date)
        try container.encodeIfPresent(dimensionsAnyCodable, forKey: .dimensions)
        if !(encoder is _ParseEncoder) {
            try container.encode(name, forKey: .name)
        }
    }
}
