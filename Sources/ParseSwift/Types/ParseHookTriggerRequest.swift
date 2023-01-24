//
//  ParseHookTriggerRequest.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/24/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

/**
 A type that can decode requests when `ParseHookTriggerable` triggers are called.
 - requires: `.usePrimaryKey` has to be available. It is recommended to only
 use the master key in server-side applications where the key is kept secure and not
 exposed to the public.
 */
public struct ParseHookTriggerRequest<U: ParseCloudUser>: ParseHookTriggerRequestable {
    public typealias UserType = U
    public var user: U?
    public var primaryKey: Bool?
    public var installationId: String?
    public var ipAddress: String?
    public var headers: [String: String]?
    public var triggerName: String?
    public var clients: Int?
    /// The  from the hook call.
    public var file: ParseFile?
    /// The size of the file in bytes.
    public var fileSize: Int?
    var log: AnyCodable?
    var context: AnyCodable?

    enum CodingKeys: String, CodingKey {
        case primaryKey = "master"
        case ipAddress = "ip"
        case user, installationId, headers,
             log, context, file, fileSize,
             clients, triggerName
    }
}
