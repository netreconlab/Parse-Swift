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
    var _failed_login_count: Int? { get }
    /// The date the lockout expires. After this date, the `ParseUser`
    /// can attempt to login again.
    var _account_lockout_expires_at: Date? { get }
}
