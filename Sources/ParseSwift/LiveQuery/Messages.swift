//
//  Messages.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/2/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

// MARK: Sending
struct StandardMessage: LiveQueryable, Codable {
    var op: ClientOperation // swiftlint:disable:this identifier_name
    var applicationId: String?
    var clientKey: String?
    var primaryKey: String?
    var sessionToken: String?
    var installationId: String?
    var requestId: Int?

    init(operation: ClientOperation, additionalProperties: Bool = false) async {
        self.op = operation
        if additionalProperties {
            self.applicationId = Parse.configuration.applicationId
            self.primaryKey = Parse.configuration.primaryKey
            self.clientKey = Parse.configuration.clientKey
            self.sessionToken = await BaseParseUser.currentContainer()?.sessionToken
            self.installationId = await BaseParseInstallation.currentContainer().installationId
        }
    }

    init(operation: ClientOperation, requestId: RequestId) async {
        await self.init(operation: operation)
        self.requestId = requestId.value
    }

    enum CodingKeys: String, CodingKey {
        case op // swiftlint:disable:this identifier_name
        case applicationId
        case clientKey
        case primaryKey = "masterKey"
        case sessionToken
        case installationId
        case requestId
    }
}

struct SubscribeQuery: Encodable {
    let className: String
    let `where`: QueryWhere
    let fields: [String]?
    let watch: [String]?
}

struct SubscribeMessage<T: ParseObject>: LiveQueryable, Encodable {
    var op: ClientOperation // swiftlint:disable:this identifier_name
    var applicationId: String?
    var clientKey: String?
    var sessionToken: String?
    var installationId: String?
    var requestId: Int?
    var query: SubscribeQuery?

    init(operation: ClientOperation,
         requestId: RequestId,
         query: Query<T>? = nil,
         additionalProperties: Bool = false) async {
        self.op = operation
        self.requestId = requestId.value
        if let query = query {
            self.query = SubscribeQuery(className: query.className,
                                        where: query.where,
                                        fields: query.fields?.sorted() ?? query.keys?.sorted(),
                                        watch: query.watch?.sorted())
        }
        self.sessionToken = await BaseParseUser.currentContainer()?.sessionToken
    }
}

// MARK: Receiving
struct RedirectResponse: LiveQueryable, Codable {
    let op: ServerResponse // swiftlint:disable:this identifier_name
    let url: URL
}

struct ConnectionResponse: LiveQueryable, Codable {
    let op: ServerResponse // swiftlint:disable:this identifier_name
    let clientId: String
    let installationId: String?
}

struct UnsubscribedResponse: LiveQueryable, Codable {
    let op: ServerResponse // swiftlint:disable:this identifier_name
    let requestId: Int
    let clientId: String
    let installationId: String?
}

struct EventResponse<T: ParseObject>: LiveQueryable, Codable {
    let op: ServerResponse // swiftlint:disable:this identifier_name
    let requestId: Int
    let object: T
    let clientId: String
    let installationId: String?
}

struct ErrorResponse: LiveQueryable, Codable {
    let op: OperationErrorResponse // swiftlint:disable:this identifier_name
    let code: Int
    let message: String
    let reconnect: Bool

    enum CodingKeys: String, CodingKey {
        case op // swiftlint:disable:this identifier_name
        case code
        case message = "error"
        case reconnect
    }
}

struct PreliminaryMessageResponse: LiveQueryable, Codable {
    let op: ServerResponse // swiftlint:disable:this identifier_name
    let requestId: Int
    let clientId: String
    let installationId: String?
}
