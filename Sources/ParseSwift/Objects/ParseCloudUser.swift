//
//  ParseCloudUser.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/14/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

/*
 A `ParseUser` that contains additional attributes
 needed for Parse hook calls.
 */
public protocol ParseCloudUser: ParseUser {

    /// The session token of the `ParseUser`.
    var sessionToken: String? { get set }

    /// The number of unsuccessful login attempts.
    var failedLoginCount: Int? { get }

    /// The number of unsuccessful login attempts.
    /// - Important: This property is required for decoding purposes.
    /// You should use `failedLoginCount` to access this value.
    var _failed_login_count: Int? { get }

    /// The date the lockout expires. After this date, the `ParseUser`
    /// can attempt to login again.
    var accountLockoutExpiresAt: Date? { get }

    /// The date the lockout expires. After this date, the `ParseUser`
    /// can attempt to login again.
    /// - Important: This property is required for decoding purposes.
    /// You should use `accountLockoutExpiresAt` to access this value.
    var _account_lockout_expires_at: Date? { get }

}

// MARK: Convenience Implementations
public extension ParseCloudUser {

    var failedLoginCount: Int? {
        _failed_login_count
    }

    var accountLockoutExpiresAt: Date? {
        _account_lockout_expires_at
    }

}
