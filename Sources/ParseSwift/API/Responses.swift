//
//  Responses.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-08-20.
//  Copyright © 2020 Parse. All rights reserved.
//

import Foundation

struct CreateResponse: Decodable {
    var objectId: String
    var createdAt: Date
    var updatedAt: Date {
        return createdAt
    }
    var sessionToken: String?

    func setResponseProperties<T>(on object: T) -> T where T: ParseObject {
        var object = object
        object.objectId = objectId
        object.createdAt = createdAt
        object.updatedAt = updatedAt
        return object
    }

    func apply<T>(to object: T) -> T where T: ParseObject {
        setResponseProperties(on: object)
    }

    func apply<T>(to user: T) -> T where T: ParseUser {
        var user = setResponseProperties(on: user)
        user.password = nil
        return user
    }

}

struct ReplaceResponse: Decodable {
    var createdAt: Date?
    var updatedAt: Date?
    var sessionToken: String?

    func setResponseProperties<T>(on object: T) throws -> T where T: ParseObject {
        guard let objectId = object.objectId else {
            throw ParseError(
                code: .missingObjectId,
                message: "Response from server should not have an objectId of nil"
            )
        }
        guard let createdAt = createdAt else {
            guard let updatedAt = updatedAt else {
                throw ParseError(
                    code: .otherCause,
                    message: "Response from server should not have an updatedAt of nil"
                )
            }
            let response = UpdateResponse(
                updatedAt: updatedAt,
                sessionToken: sessionToken
            ).apply(to: object)

            return response
        }
        let response = CreateResponse(
            objectId: objectId,
            createdAt: createdAt,
            sessionToken: sessionToken
        ).apply(to: object)

        return response
    }

    func apply<T>(to object: T) throws -> T where T: ParseObject {
        try setResponseProperties(on: object)
    }

    func apply<T>(to user: T) throws -> T where T: ParseUser {
        var user = try setResponseProperties(on: user)
        user.password = nil // password should be removed
        return user
    }
}

struct UpdateResponse: Decodable {
    var updatedAt: Date
    var sessionToken: String?

    func setResponseProperties<T>(on object: T) -> T where T: ParseObject {
        var object = object
        object.updatedAt = updatedAt
        return object
    }

    func apply<T>(to object: T) -> T where T: ParseObject {
        setResponseProperties(on: object)
    }

    func apply<T>(to user: T) -> T where T: ParseUser {
        var user = setResponseProperties(on: user)
        user.password = nil // password should be removed
        return user
    }
}

// MARK: ParseObject Batch
struct BatchResponseItem<T>: Codable where T: Codable {
    let success: T?
    let error: ParseError?
}

struct BatchResponse: Codable {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var sessionToken: String?

    func asCreateResponse() throws -> CreateResponse {
        guard let objectId = objectId else {
            throw ParseError(
                code: .missingObjectId,
                message: "Response from server should not have an objectId of nil"
            )
        }
        guard let createdAt = createdAt else {
            throw ParseError(
                code: .otherCause,
                message: "Response from server should not have an createdAt of nil"
            )
        }

        let response = CreateResponse(
            objectId: objectId,
            createdAt: createdAt, sessionToken: sessionToken
        )

        return response
    }

    func asReplaceResponse() -> ReplaceResponse {
        ReplaceResponse(
            createdAt: createdAt,
            updatedAt: updatedAt,
            sessionToken: sessionToken
        )
    }

    func asUpdateResponse() throws -> UpdateResponse {
        guard let updatedAt = updatedAt else {
            throw ParseError(
                code: .otherCause,
                message: "Response from server should not have an updatedAt of nil"
            )
        }
        let response = UpdateResponse(
            updatedAt: updatedAt,
            sessionToken: sessionToken
        )
        return response
    }

    func apply<T>(to object: T, method: API.Method) throws -> T where T: ParseObject {
        switch method {
        case .POST:
            return try asCreateResponse().apply(to: object)
        case .PUT:
            return try asReplaceResponse().apply(to: object)
        case .PATCH:
            return try asUpdateResponse().apply(to: object)
        case .GET:
            fatalError("Parse-server does not support batch fetching like this. Try \"fetchAll\".")
        default:
            fatalError("There is no configured way to apply for method: \(method)")
        }
    }
}

// MARK: Query
struct QueryResponse<T>: Codable where T: ParseObject {
    let results: [T]
    let count: Int?
}

// MARK: ParseUser
struct LoginSignupResponse: Codable {
    let createdAt: Date
    let objectId: String
    let sessionToken: String
    var updatedAt: Date?
    let username: String?

    func apply<T>(to user: T) -> T where T: ParseUser {
        var user = user
        user.objectId = objectId
        user.createdAt = createdAt
        user.updatedAt = updatedAt ?? createdAt
        user.password = nil // password should be removed

        return user
    }
}

// MARK: ParseFile
struct FileUploadResponse: Codable {
    let name: String
    let url: URL

    func apply(to file: ParseFile) -> ParseFile {
        var file = file
        file.name = name
        file.url = url
        return file
    }
}

// MARK: AnyResultResponse
struct AnyResultResponse<U: Decodable>: Decodable {
    let result: U
}

// MARK: AnyResultsResponse
struct AnyResultsResponse<U: Decodable>: Decodable {
    let results: [U]
}

struct AnyResultsMongoResponse<U: Decodable>: Decodable {
    let results: U
}

// MARK: ConfigResponse
struct ConfigFetchResponse<T>: Codable where T: ParseConfig {
    let params: T
}

struct BooleanResponse: Codable {
    let result: Bool
}

// MARK: HealthResponse
struct HealthResponse: Codable {
    let status: ParseServer.Status
}

// MARK: PushResponse
struct PushResponse: Codable {
    let data: Data
    let statusId: String
}
