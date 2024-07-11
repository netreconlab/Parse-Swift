//
//  API.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-08-19.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// swiftlint:disable line_length

/// The REST API for communicating with a Parse Server.
public struct API {

    public enum Method: String, Encodable, Sendable {
        case GET, POST, PUT, PATCH, DELETE
    }

    public enum Endpoint: Encodable, Sendable {
        case batch
        case objects(className: String)
        case object(className: String, objectId: String)
        case users
        case user(objectId: String)
        case installations
        case installation(objectId: String)
        case sessions
        case session(objectId: String)
        case event(event: String)
        case roles
        case role(objectId: String)
        case login
        case loginAs
        case logout
        case file(fileName: String)
        case passwordReset
        case verifyPassword
        case verificationEmail
        case functions(name: String)
        case jobs(name: String)
        case aggregate(className: String)
        case config
        case health
        case schemas
        case schema(className: String)
        case purge(className: String)
        case push
        case hookFunctions
        case hookFunction(request: FunctionRequest)
        case hookTriggers
        case hookTrigger(request: TriggerRequest)
        case serverInfo
        case any(String)

        public var urlComponent: String {
            switch self {
            case .batch:
                return "/batch"
            case .objects(let className):
                return "/classes/\(className)"
            case .object(let className, let objectId):
                return "/classes/\(className)/\(objectId)"
            case .users:
                return "/users"
            case .user(let objectId):
                return "/users/\(objectId)"
            case .installations:
                return "/installations"
            case .installation(let objectId):
                return "/installations/\(objectId)"
            case .sessions:
                return "/sessions"
            case .session(let objectId):
                return "/sessions/\(objectId)"
            case .event(let event):
                return "/events/\(event)"
            case .aggregate(let className):
                return "/aggregate/\(className)"
            case .roles:
                return "/roles"
            case .role(let objectId):
                return "/roles/\(objectId)"
            case .login:
                return "/login"
            case .loginAs:
                return "/loginAs"
            case .logout:
                return "/logout"
            case .file(let fileName):
                return "/files/\(fileName)"
            case .passwordReset:
                return "/requestPasswordReset"
            case .verifyPassword:
                return "/verifyPassword"
            case .verificationEmail:
                return "/verificationEmailRequest"
            case .functions(name: let name):
                return "/functions/\(name)"
            case .jobs(name: let name):
                return "/jobs/\(name)"
            case .config:
                return "/config"
            case .health:
                return "/health"
            case .schemas:
                return "/schemas"
            case .schema(let className):
                return "/schemas/\(className)"
            case .purge(let className):
                return "/purge/\(className)"
            case .push:
                return "/push"
            case .hookFunctions:
                return "/hooks/functions/"
            case .hookFunction(let request):
                return "/hooks/functions/\(request.functionName)"
            case .hookTriggers:
                return "/hooks/triggers/"
            case .hookTrigger(let request):
                return "/hooks/triggers/\(request.className)/\(request.trigger)"
            case .serverInfo:
                return "/serverInfo"
            case .any(let path):
                return path
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(urlComponent)
        }
    }

    /// A type alias for the set of options.
    public typealias Options = Set<API.Option>

    /// Options available to send to Parse Server.
    public enum Option: Hashable, Sendable {

        /// Use the primaryKey/masterKey if it was provided during initial configuraration.
        case usePrimaryKey
        /// Use a specific session token.
        /// - note: The session token of the current user is provided by default.
        case sessionToken(String)
        /// Use a specific installationId.
        /// - note: The installationId of the current user is provided by default.
        case installationId(String)
        /// Specify mimeType.
        case mimeType(String)
        /// Specify fileSize.
        case fileSize(String)
        /// Remove mimeType.
        /// - note: This is typically used indirectly by `ParseFile`.
        case removeMimeType
        /// Specify metadata.
        /// - note: This is typically used indirectly by `ParseFile`.
        case metadata([String: String])
        /// Specify tags.
        /// - note: This is typically used indirectly by `ParseFile`.
        case tags([String: String])
        /// Add context.
        /// - warning: Requires Parse Server 5.0.0+.
        case context(Encodable & Sendable)
        /// The caching policy to use for a specific http request. Determines when to
        /// return a response from the cache. See Apple's
        /// [documentation](https://developer.apple.com/documentation/foundation/url_loading_system/accessing_cached_data)
        /// for more info.
        case cachePolicy(URLRequest.CachePolicy)
        /// Use a specific server URL.
        /// - note: The URL of the Swift SDK is provided by default. Only set this
        /// option if you need to connect to a different server than the one configured.
        case serverURL(String)

        // swiftlint:disable:next cyclomatic_complexity
        public func hash(into hasher: inout Hasher) {
            switch self {
            case .usePrimaryKey:
                hasher.combine(1)
            case .sessionToken:
                hasher.combine(2)
            case .installationId:
                hasher.combine(3)
            case .mimeType:
                hasher.combine(4)
            case .fileSize:
                hasher.combine(5)
            case .removeMimeType:
                hasher.combine(6)
            case .metadata:
                hasher.combine(7)
            case .tags:
                hasher.combine(8)
            case .context:
                hasher.combine(9)
            case .cachePolicy:
                hasher.combine(10)
            case .serverURL:
                hasher.combine(11)
            }
        }

        // swiftlint:disable:next cyclomatic_complexity
        public static func == (lhs: API.Option, rhs: API.Option) -> Bool {
            switch (lhs, rhs) {
            case (.usePrimaryKey, .usePrimaryKey): return true
            case (.removeMimeType, .removeMimeType): return true
            case (.sessionToken(let object1), .sessionToken(let object2)): return object1 == object2
            case (.installationId(let object1), .installationId(let object2)): return object1 == object2
            case (.mimeType(let object1), .mimeType(let object2)): return object1 == object2
            case (.fileSize(let object1), .fileSize(let object2)): return object1 == object2
            case (.metadata(let object1), .metadata(let object2)): return object1 == object2
            case (.tags(let object1), .tags(let object2)): return object1 == object2
            case (.context(let object1), .context(let object2)): return object1.isEqual(object2)
            case (.cachePolicy(let object1), .cachePolicy(let object2)): return object1 == object2
            case (.serverURL(let object1), .serverURL(let object2)): return object1 == object2
            default: return false
            }
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    internal static func getHeaders(options: API.Options) async throws -> [String: String] {
        try await yieldIfNotInitialized()
        var headers: [String: String] = ["X-Parse-Application-Id": Parse.configuration.applicationId,
                                         "Content-Type": "application/json"]
        if let clientKey = Parse.configuration.clientKey {
            headers["X-Parse-Client-Key"] = clientKey
        }

        if let token = await BaseParseUser.currentContainer()?.sessionToken {
            headers["X-Parse-Session-Token"] = token
        }

        if let installationId = await BaseParseInstallation.currentContainer().installationId {
            headers["X-Parse-Installation-Id"] = installationId
        }

        headers["X-Parse-Client-Version"] = clientVersion()
        headers["X-Parse-Request-Id"] = Self.createUniqueRequestId()

        options.forEach { option in
            switch option {
            case .usePrimaryKey:
                headers["X-Parse-Master-Key"] = Parse.configuration.primaryKey
            case .sessionToken(let sessionToken):
                headers["X-Parse-Session-Token"] = sessionToken
            case .installationId(let installationId):
                headers["X-Parse-Installation-Id"] = installationId
            case .mimeType(let mimeType):
                headers["Content-Type"] = mimeType
            case .fileSize(let fileSize):
                headers["Content-Length"] = fileSize
            case .removeMimeType:
                headers.removeValue(forKey: "Content-Type")
            case .metadata(let metadata):
                metadata.forEach {(key, value) in
                    headers[key] = value
                }
            case .tags(let tags):
                tags.forEach {(key, value) in
                    headers[key] = value
                }
            case .context(let context):
                let context = AnyEncodable(context)
                if let encoded = try? ParseCoding.jsonEncoder().encode(context) {
                    let encodedString = String(decoding: encoded, as: UTF8.self)
                    headers["X-Parse-Cloud-Context"] = encodedString
                }
            default:
                break
            }
        }
        return headers
    }

    internal static func createUniqueRequestId() -> String {
        UUID().uuidString.lowercased()
    }

    internal static func clientVersion() -> String {
        ParseConstants.sdk+ParseConstants.version
    }

    internal static func serverURL(options: API.Options) -> URL {
        var optionURL: URL?
        // BAKER: Currently have to step through all options and
        // break to get the current URL.
        for option in options {
            switch option {
            case .serverURL(let url):
                optionURL = URL(string: url)
            default:
                continue
            }
            break
        }

        guard let currentURL = optionURL else {
            return Parse.configuration.serverURL
        }
        return currentURL
    }
}
