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
 use the primary key in server-side applications where the key is kept secure and not
 exposed to the public.
 */
public struct ParseHookTriggerRequest<U: ParseCloudUser>: ParseHookTriggerRequestable {
    public typealias UserType = U
    public var user: U?
    public var primaryKey: Bool?
    public var installationId: String?
    public var ipAddress: String?
    public var headers: [String: String]?
    /// The type of Parse Hook Trigger.
    public var trigger: ParseHookTriggerType?
    public var clients: Int?
    /// The  from the hook call.
    public var file: ParseFile?
    /// The size of the file in bytes.
    public var fileSize: Int?
	/// Force `ParseFile` download.
	public var forceDownload: Bool?
    var log: AnyCodable?
    var context: AnyCodable?

    enum CodingKeys: String, CodingKey {
        case primaryKey = "master"
        case ipAddress = "ip"
        case trigger = "triggerName"
        case user, installationId, headers,
             log, context, file, fileSize,
             clients, forceDownload
    }
}

extension ParseHookTriggerRequest {

    /**
     Get the Parse Server logger using any type that conforms to `Codable`.
     - returns: The sound casted to the inferred type.
     - throws: An error of type `ParseError`.
     */
    public func getLog<V>() throws -> V where V: Codable {
        guard let log = log?.value as? V else {
            throw ParseError(code: .otherCause,
                             message: "Cannot be casted to the inferred type")
        }
        return log
    }

    /**
     Get the context using any type that conforms to `Codable`.
     - returns: The sound casted to the inferred type.
     - throws: An error of type `ParseError`.
     */
    public func getContext<V>() throws -> V where V: Codable {
        guard let context = context?.value as? V else {
            throw ParseError(code: .otherCause,
                             message: "Cannot be casted to the inferred type")
        }
        return context
    }

}
