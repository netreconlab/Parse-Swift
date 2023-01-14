//
//  Utility.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/14/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

struct Utility {

    static func updateParseURLSession() {
        #if !os(Linux) && !os(Android) && !os(Windows)
        if !Parse.configuration.isTestingSDK {
            let configuration = URLSessionConfiguration.default
            configuration.urlCache = URLCache.parse
            configuration.requestCachePolicy = Parse.configuration.requestCachePolicy
            configuration.httpAdditionalHeaders = Parse.configuration.httpAdditionalHeaders
            URLSession.parse = URLSession(configuration: configuration,
                                          delegate: Parse.sessionDelegate,
                                          delegateQueue: nil)
        } else {
            let session = URLSession.shared
            session.configuration.urlCache = URLCache.parse
            session.configuration.requestCachePolicy = Parse.configuration.requestCachePolicy
            session.configuration.httpAdditionalHeaders = Parse.configuration.httpAdditionalHeaders
            URLSession.parse = session
        }
        #endif

    }

    static func reconnectInterval(_ maxExponent: Int) -> Int {
        let min = NSDecimalNumber(decimal: Swift.min(30, pow(2, maxExponent) - 1))
        return Int.random(in: 0 ..< Int(truncating: min))
    }

    static func computeDelay(_ seconds: Int) -> TimeInterval? {
        Calendar.current.date(byAdding: .second,
                              value: seconds,
                              to: Date())?.timeIntervalSinceNow
    }

    static func computeDelay(_ delayString: String) -> TimeInterval? {

        guard let seconds = Int(delayString) else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "E, d MMM yyyy HH:mm:ss z"
            guard let delayUntil = dateFormatter.date(from: delayString) else {
                return nil
            }
            return delayUntil.timeIntervalSinceNow
        }
        return computeDelay(seconds)
    }

}
