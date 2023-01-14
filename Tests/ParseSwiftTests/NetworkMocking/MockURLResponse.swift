//
//  MockURLResponse.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 7/18/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation
@testable import ParseSwift

struct MockURLResponse {
    var statusCode: Int = 200
    var headerFields = [String: String]()
    var responseData: Data?
    var delay: TimeInterval = Self.addRandomDelay(1)
    var error: Error?

    init(error: Error) {
        self.error = error
        self.responseData = nil
        self.statusCode = 400
    }

    init(string: String) throws {
        try self.init(string: string, statusCode: 200)
    }

    init(string: String,
         statusCode: Int,
         delay: TimeInterval? = nil,
         headerFields: [String: String] = ["Content-Type": "application/json"]) throws {
        let encoded = try JSONEncoder().encode(string)
        self.init(data: encoded,
                  statusCode: statusCode,
                  delay: delay,
                  headerFields: headerFields)
    }

    init(data: Data,
         statusCode: Int,
         delay: TimeInterval? = nil,
         headerFields: [String: String] = ["Content-Type": "application/json"]) {
        self.statusCode = statusCode
        self.headerFields = headerFields
        self.responseData = data
        if let delay = delay {
            self.delay = delay
        }
        self.error = nil
    }

    static func addRandomDelay(_ delayMax: Int) -> TimeInterval {
        let delayInSeconds = Utility.reconnectInterval(delayMax)
        return Utility.computeDelay(delayInSeconds) ?? TimeInterval(0.5)
    }

}
