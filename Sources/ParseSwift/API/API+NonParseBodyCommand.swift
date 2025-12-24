//
//  API+NonParseBodyCommand.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/12/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

internal extension API {
    // MARK: API.NonParseBodyCommand
    struct NonParseBodyCommand<T, U>: Encodable where T: Encodable & Sendable, U: Sendable {
        typealias ReturnType = U // swiftlint:disable:this nesting
        let method: API.Method
        let path: API.Endpoint
        let body: T?
        let mapper: (@Sendable (Data) async throws -> U)
        let params: [String: String?]?

        init(method: API.Method,
             path: API.Endpoint,
             params: [String: String]? = nil,
             body: T? = nil,
             mapper: @escaping (@Sendable (Data) async throws -> U)) {
            self.method = method
            self.path = path
            self.params = params
            self.body = body
            self.mapper = mapper
        }

        // MARK: Asynchronous Execution
        func execute(options: API.Options,
                     callbackQueue: DispatchQueue,
                     allowIntermediateResponses: Bool = false,
                     completion: @escaping @Sendable (Result<U, ParseError>) -> Void) async {

            switch await self.prepareURLRequest(options: options) {
            case .success(let urlRequest):
                await URLSession.parse.dataTask(with: urlRequest,
                                                callbackQueue: callbackQueue,
                                                allowIntermediateResponses: allowIntermediateResponses,
                                                mapper: mapper) { result in
                    callbackQueue.async {
                        switch result {

                        case .success(let decoded):
                            completion(.success(decoded))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                }
            case .failure(let error):
                callbackQueue.async {
                    completion(.failure(error))
                }
            }
        }

        // MARK: URL Preperation
        func prepareURLRequest(options: API.Options) async -> Result<URLRequest, ParseError> {
            let params = self.params?.getURLQueryItems()
            do {
                var headers = try await API.getHeaders(options: options)
                if method == .GET ||
                    method == .DELETE {
                    headers.removeValue(forKey: "X-Parse-Request-Id")
                }
                let url = API.serverURL(options: options).appendingPathComponent(path.urlComponent)

                guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                    return .failure(ParseError(code: .otherCause,
                                               message: "Could not unwrap url components for \(url)"))
                }
                components.queryItems = params
                components.percentEncodedQuery = components.percentEncodedQuery?
                    .replacingOccurrences(
                        of: "+",
                        with: "%2B"
                    )

                guard let urlComponents = components.url else {
                    return .failure(ParseError(code: .otherCause,
                                               message: "Could not create url from components for \(components)"))
                }

                var urlRequest = URLRequest(url: urlComponents)
                urlRequest.allHTTPHeaderFields = headers
                if let urlBody = body {
                    do {
                        let bodyData = try ParseCoding.jsonEncoder().encode(urlBody)
                        urlRequest.httpBody = bodyData
                    } catch {
                        return .failure(ParseError(code: .otherCause,
                                                   message: "Could not encode body \(urlBody)",
                                                   swift: error))
                    }
                }
                urlRequest.httpMethod = method.rawValue
                urlRequest.cachePolicy = requestCachePolicy(options: options)
                return .success(urlRequest)
            } catch {
                let parseError = error as? ParseError ?? ParseError(swift: error)
                return .failure(parseError)
            }
        }

        enum CodingKeys: String, CodingKey { // swiftlint:disable:this nesting
            case method, body, path
        }
    }
}

internal extension API.NonParseBodyCommand {

    // MARK: Deleting
    static func delete<V>(_ object: V) throws -> API.NonParseBodyCommand<NoBody, NoBody> where V: ParseObject {
        guard object.isSaved else {
            throw ParseError(code: .otherCause,
                             message: "Cannot delete an object without an objectId")
        }

        let mapper = { @Sendable (data: Data) -> NoBody in
            if let error = try? ParseCoding
                .jsonDecoder()
                .decode(ParseError.self,
                        from: data) {
                throw error
            } else {
                return NoBody()
            }
        }

        return API.NonParseBodyCommand<NoBody, NoBody>(method: .DELETE,
                                                       path: object.endpoint,
                                                       mapper: mapper)
    }
}

internal extension API.NonParseBodyCommand {
    // MARK: Batch - Child Objects
    // swiftlint:disable:next function_body_length
    static func batch(objects: [ParseEncodable],
                      transaction: Bool,
                      objectsSavedBeforeThisOne: [String: PointerType]?,
                      // swiftlint:disable:next line_length
                      filesSavedBeforeThisOne: [String: ParseFile]?) async throws -> RESTBatchCommandTypeEncodablePointer<AnyCodable> {

        let defaultACL = try? await ParseACL.defaultACL()
        let batchCommands = try objects.compactMap { (object) -> API.BatchCommand<AnyCodable, PointerType>? in
            guard var objectable = object as? Objectable else {
                return nil
            }
            let method: API.Method!
            if objectable.isSaved {
                method = .PUT
            } else {
                method = .POST
            }

            let mapper = { (baseObjectable: BaseObjectable) throws -> PointerType in
                objectable.objectId = baseObjectable.objectId
                return try objectable.toPointer()
            }

            let path = Parse.configuration.mountPath + objectable.endpoint.urlComponent
            let encoded = try ParseCoding
				.parseEncoder()
				.encode(
					object,
					acl: defaultACL,
					batching: true,
					objectsSavedBeforeThisOne: objectsSavedBeforeThisOne,
					filesSavedBeforeThisOne: filesSavedBeforeThisOne
				)
            let body = try ParseCoding.jsonDecoder().decode(AnyCodable.self, from: encoded)
            return API.BatchCommand<AnyCodable, PointerType>(method: method,
                                                             path: .any(path),
                                                             body: body,
                                                             mapper: mapper)
        }

        let mapper = { @Sendable (data: Data) -> [Result<PointerType, ParseError>] in
            let decodingType = [BatchResponseItem<BaseObjectable>].self
            do {
                let responses = try ParseCoding.jsonDecoder().decode(decodingType, from: data)
                return batchCommands.enumerated().map({ (object) -> (Result<PointerType, ParseError>) in
                    let response = responses[object.offset]
                    if let success = response.success {
                        guard let successfulResponse = try? object.element.mapper(success) else {
                            return .failure(ParseError(code: .otherCause, message: "Unknown error"))
                        }
                        return .success(successfulResponse)
                    } else {
                        let parseError = response.error ?? ParseError(code: .otherCause,
                                                                      message: "Unknown error")
                        return .failure(parseError)
                    }
                })
            } catch {
                let parseError = error as? ParseError ?? ParseError(code: .otherCause,
                                                                    message: "Decoding error",
                                                                    swift: error)
                return [(.failure(parseError))]
            }
        }
        let batchCommand = BatchChildCommand(requests: batchCommands,
                                             transaction: transaction)
        return RESTBatchCommandTypeEncodablePointer<AnyCodable>(method: .POST,
                                                                path: .batch,
                                                                body: batchCommand,
                                                                mapper: mapper)
    }
}
