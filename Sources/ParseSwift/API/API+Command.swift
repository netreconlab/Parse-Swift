//
//  API+Command.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-09-24.
//  Copyright © 2020 Parse. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

internal extension API {
    // MARK: API.Command
    // swiftlint:disable:next type_body_length
    struct Command<T, U>: Encodable, Sendable where T: ParseEncodable, U: Sendable {
        typealias ReturnType = U // swiftlint:disable:this nesting
        let method: API.Method
        let path: API.Endpoint
        let body: T?
        let mapper: (@Sendable (Data) async throws -> U)
        let params: [String: String?]?
        let uploadData: Data?
        let uploadFile: URL?
        let parseURL: URL?
        let otherURL: URL?
        let stream: InputStream?

        init(method: API.Method,
             path: API.Endpoint,
             params: [String: String]? = nil,
             body: T? = nil,
             uploadData: Data? = nil,
             uploadFile: URL? = nil,
             parseURL: URL? = nil,
             otherURL: URL? = nil,
             stream: InputStream? = nil,
             mapper: @escaping (@Sendable (Data) async throws -> U)) {
            self.method = method
            self.path = path
            self.body = body
            self.uploadData = uploadData
            self.uploadFile = uploadFile
            self.parseURL = parseURL
            self.otherURL = otherURL
            self.stream = stream
            self.mapper = mapper
            self.params = params
        }

        // MARK: Asynchronous Execution
        func executeStream(options: API.Options,
                           callbackQueue: DispatchQueue,
                           childObjects: [String: PointerType]? = nil,
                           childFiles: [String: ParseFile]? = nil,
                           uploadProgress: (@Sendable (URLSessionTask, Int64, Int64, Int64) -> Void)? = nil,
                           stream: InputStream,
                           completion: @escaping @Sendable (ParseError?) -> Void) {
            guard method == .POST ||
                    method == .PUT ||
                    method == .PATCH else {
                callbackQueue.async {
                    completion(nil)
                }
                return
            }
            self.prepareURLRequest(options: options,
                                   batching: false,
                                   childObjects: childObjects,
                                   childFiles: childFiles) { result in
                switch result {
                case .success(let urlRequest):
                    let task = URLSession.parse.uploadTask(withStreamedRequest: urlRequest)
                    Parse.sessionDelegate.streamDelegates[task] = stream
                    Task {
                        await Parse.sessionDelegate.delegates.updateUpload(task, callback: uploadProgress)
                        await Parse.sessionDelegate.delegates.updateTask(task, queue: callbackQueue)
                        task.resume()
                        callbackQueue.async {
                            completion(nil)
                        }
                    }
                    return
                case .failure(let error):
                    callbackQueue.async {
                        completion(error)
                    }
                }
            }
        }

        // swiftlint:disable:next function_body_length cyclomatic_complexity
        func execute(options: API.Options,
                     batching: Bool = false,
                     callbackQueue: DispatchQueue,
                     notificationQueue: DispatchQueue? = nil,
                     childObjects: [String: PointerType]? = nil,
                     childFiles: [String: ParseFile]? = nil,
                     allowIntermediateResponses: Bool = false,
                     uploadProgress: ((URLSessionTask, Int64, Int64, Int64) -> Void)? = nil,
                     downloadProgress: ((URLSessionDownloadTask, Int64, Int64, Int64) -> Void)? = nil,
                     completion: @escaping @Sendable (Result<U, ParseError>) -> Void) async {
            let currentNotificationQueue: DispatchQueue!
            if let notificationQueue = notificationQueue {
                currentNotificationQueue = notificationQueue
            } else {
                currentNotificationQueue = callbackQueue
            }
            if !path.urlComponent.contains("/files/") {
                // All ParseObjects use the shared URLSession
                switch await self.prepareURLRequest(options: options,
                                                    batching: batching,
                                                    childObjects: childObjects,
                                                    childFiles: childFiles) {
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
            } else {
                // ParseFiles are handled with a dedicated URLSession
                if method == .POST ||
                    method == .PUT ||
                    method == .PATCH {
                    switch await self.prepareURLRequest(options: options,
                                                        batching: batching,
                                                        childObjects: childObjects,
                                                        childFiles: childFiles) {

                    case .success(let urlRequest):

                        URLSession
                            .parse
                            .uploadTask(notificationQueue: currentNotificationQueue,
                                        with: urlRequest,
                                        from: uploadData,
                                        from: uploadFile,
                                        progress: uploadProgress,
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
                } else if method == .DELETE {

                    switch await self.prepareURLRequest(options: options,
                                                        batching: batching,
                                                        childObjects: childObjects,
                                                        childFiles: childFiles) {
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

                } else {

                    if parseURL != nil {
                        switch await self.prepareURLRequest(options: options,
                                                            batching: batching,
                                                            childObjects: childObjects,
                                                            childFiles: childFiles) {

                        case .success(let urlRequest):
                            await URLSession
                                .parse
                                .downloadTask(notificationQueue: currentNotificationQueue,
                                              with: urlRequest,
                                              progress: downloadProgress,
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
                    } else if let otherURL = self.otherURL {
                        // Non-parse servers do not receive any parse dedicated request info
                        var request = URLRequest(url: otherURL)
                        request.cachePolicy = requestCachePolicy(options: options)
                        URLSession.parse.downloadTask(with: request, mapper: mapper) { result in
                            callbackQueue.async {
                                switch result {

                                case .success(let decoded):
                                    completion(.success(decoded))
                                case .failure(let error):
                                    completion(.failure(error))
                                }
                            }
                        }
                    } else {
                        callbackQueue.async {
                            completion(.failure(ParseError(code: .otherCause,
                                                           // swiftlint:disable:next line_length
                                                           message: "Cannot download the file without specifying the url")))
                        }
                    }
                }
            }
        }

        // MARK: URL Preperation
        // swiftlint:disable:next function_body_length
        func prepareURLRequest(options: API.Options,
                               batching: Bool = false,
                               childObjects: [String: PointerType]? = nil,
                               childFiles: [String: ParseFile]? = nil,
                               completion: @escaping @Sendable (Result<URLRequest, ParseError>) -> Void) {
            let params = self.params?.getURLQueryItems()
            Task {
                do {
                    var headers = try await API.getHeaders(options: options)
                    if method == .GET ||
                        method == .DELETE {
                        headers.removeValue(forKey: "X-Parse-Request-Id")
                    }
                    let url = parseURL == nil ?
                    API.serverURL(options: options).appendingPathComponent(path.urlComponent) : parseURL!

                    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                        let error = ParseError(code: .otherCause,
                                               message: "Could not unrwrap url components for \(url)")
                        completion(.failure(error))
                        return
                    }
                    components.queryItems = params
                    components.percentEncodedQuery = components.percentEncodedQuery?
                        .replacingOccurrences(
                            of: "+",
                            with: "%2B"
                        )

                    guard let urlComponents = components.url else {
                        let error = ParseError(code: .otherCause,
                                               message: "Could not create url from components for \(components)")
                        completion(.failure(error))
                        return
                    }

                    var urlRequest = URLRequest(url: urlComponents)
                    urlRequest.allHTTPHeaderFields = headers
                    if let urlBody = body {
                        if (urlBody as? ParseCloudTypeable) != nil {
                            do {
                                let bodyData = try ParseCoding
									.parseEncoder()
									.encode(
										urlBody,
										skipKeys: .cloud
								)
                                urlRequest.httpBody = bodyData
                            } catch {
                                let defaultError = ParseError(code: .otherCause,
                                                              message: "Could not encode body \(urlBody)",
                                                              swift: error)
                                let parseError = error as? ParseError ?? defaultError
                                completion(.failure(parseError))
                                return
                            }
                        } else {
                            guard let bodyData = try? ParseCoding
                                .parseEncoder()
                                .encode(
									urlBody,
									batching: batching,
									collectChildren: false,
									objectsSavedBeforeThisOne: childObjects,
									filesSavedBeforeThisOne: childFiles
								) else {
                                let error = ParseError(code: .otherCause,
                                                       message: "Could not encode body \(urlBody)")
                                completion(.failure(error))
                                return
                            }
                            urlRequest.httpBody = bodyData.encoded
                        }
                    }
                    urlRequest.httpMethod = method.rawValue
                    urlRequest.cachePolicy = requestCachePolicy(options: options)
                    completion(.success(urlRequest))
                    return
                } catch {
                    let parseError = error as? ParseError ?? ParseError(swift: error)
                    completion(.failure(parseError))
                    return
                }
            }
        }

        enum CodingKeys: String, CodingKey { // swiftlint:disable:this nesting
            case method, body, path
        }
    }

    static func requestCachePolicy(options: API.Options) -> URLRequest.CachePolicy {
        var policy: URLRequest.CachePolicy = Parse.configuration.requestCachePolicy
        options.forEach { option in
            if case .cachePolicy(let updatedPolicy) = option {
                policy = updatedPolicy
            }
        }
        return policy
    }
}

internal extension API.Command {

    // MARK: Uploading File
    static func uploadFile(_ object: ParseFile) throws -> API.Command<ParseFile, ParseFile> {
        if !object.isSaved {
            return createFile(object)
        } else {
            throw ParseError(code: .otherCause,
                             message: "File is already saved and cannot be updated.")
        }
    }

    // MARK: Uploading File - private
    private static func createFile(_ object: ParseFile) -> API.Command<ParseFile, ParseFile> {
        API.Command(method: .POST,
                    path: .file(fileName: object.name),
                    uploadData: object.data,
                    uploadFile: object.localURL) { (data) -> ParseFile in
            try ParseCoding.jsonDecoder().decode(FileUploadResponse.self, from: data).apply(to: object)
        }
    }

    // MARK: Downloading File
    static func downloadFile(_ object: ParseFile) -> API.Command<ParseFile, ParseFile> {
        API.Command(method: .GET,
                    path: .file(fileName: object.name),
                    parseURL: object.url,
                    otherURL: object.cloudURL) { (data) -> ParseFile in
            let tempFileLocation = try ParseCoding.jsonDecoder().decode(URL.self, from: data)
            guard let fileManager = ParseFileManager() else {
                throw ParseError(code: .otherCause, message: "Cannot create fileManager")
            }
            let downloadDirectoryPath = try ParseFileManager.downloadDirectory()
            try fileManager.createDirectoryIfNeeded(downloadDirectoryPath.relativePath)
            let fileNameURL = URL(fileURLWithPath: object.name)
            let fileLocation = downloadDirectoryPath.appendingPathComponent(fileNameURL.lastPathComponent)
            if tempFileLocation != fileLocation {
                try? FileManager.default.removeItem(at: fileLocation) // Remove file if it is already present
                try FileManager.default.moveItem(at: tempFileLocation, to: fileLocation)
            }
            var object = object
            object.localURL = fileLocation
            return object
        }
    }

    // MARK: Deleting File
    static func deleteFile(_ object: ParseFile) -> API.Command<ParseFile, NoBody> {
        API.Command(method: .DELETE,
                    path: .file(fileName: object.name),
                    parseURL: object.url) { (data) -> NoBody in
            let parseError: ParseError!
            do {
                parseError = try ParseCoding.jsonDecoder().decode(ParseError.self, from: data)
            } catch {
                return try ParseCoding.jsonDecoder().decode(NoBody.self, from: data)
            }
            throw parseError
        }
    }

    // MARK: Saving ParseObjects
    static func save<V>(_ object: V,
                        original data: Data?,
                        ignoringCustomObjectIdConfig: Bool,
                        batching: Bool = false) async throws -> API.Command<V, V> where V: ParseObject {
        if Parse.configuration.isRequiringCustomObjectIds &&
            object.objectId == nil &&
            !ignoringCustomObjectIdConfig {
            throw ParseError(code: .missingObjectId, message: "objectId must not be nil")
        }
        if try await object.isSaved() {
            // MARK: Should be switched to "update" when server supports PATCH.
            return try replace(object,
                               original: data)
        }
        return try await create(object)
    }

    static func create<V>(_ object: V) async throws -> API.Command<V, V> where V: ParseObject {
        var object = object
        if object.ACL == nil,
            let acl = try? await ParseACL.defaultACL() {
            object.ACL = acl
        }
        let updatedObject = object
        let mapper = { @Sendable (data) -> V in
			do {
				// Try to decode CreateResponse, if that doesn't work try Pointer
				let savedObject = try ParseCoding.jsonDecoder().decode(
					CreateResponse.self,
					from: data
				).apply(
					to: updatedObject
				)
				return savedObject
			} catch let originalError {
				do {
					let pointer = try ParseCoding.jsonDecoder().decode(
						Pointer<V>.self,
						from: data
					)
					let fetchedObject = try await pointer.fetch()
					return fetchedObject
				} catch {
					throw originalError
				}
			}
        }
        return API.Command<V, V>(method: .POST,
                                 path: try await object.endpoint(.POST),
                                 body: object,
                                 mapper: mapper)
    }

    static func replace<V>(_ object: V,
                           original data: Data?) throws -> API.Command<V, V> where V: ParseObject {
        guard object.objectId != nil else {
            throw ParseError(code: .missingObjectId,
                             message: "objectId must not be nil")
        }
        let mapper = { @Sendable (mapperData: Data) -> V in
            var updatedObject = object
            updatedObject.originalData = nil
            updatedObject = try ParseCoding
                .jsonDecoder()
                .decode(ReplaceResponse.self, from: mapperData)
                .apply(to: updatedObject)
            guard let originalData = data,
                  let original = try? ParseCoding.jsonDecoder().decode(V.self,
                                                                       from: originalData),
                  original.hasSameObjectId(as: updatedObject) else {
                      return updatedObject
                  }
            return try updatedObject.merge(with: original)
        }
        return API.Command<V, V>(method: .PUT,
                                 path: object.endpoint,
                                 body: object,
                                 mapper: mapper)
    }

    static func update<V>(_ object: V,
                          original data: Data?) throws -> API.Command<V, V> where V: ParseObject {
        guard object.objectId != nil else {
            throw ParseError(code: .missingObjectId,
                             message: "objectId must not be nil")
        }
        let mapper = { @Sendable (mapperData: Data) -> V in
            var updatedObject = object
            updatedObject.originalData = nil
            updatedObject = try ParseCoding
                .jsonDecoder()
                .decode(UpdateResponse.self, from: mapperData)
                .apply(to: updatedObject)
            guard let originalData = data,
                  let original = try? ParseCoding.jsonDecoder().decode(V.self,
                                                                       from: originalData),
                  original.hasSameObjectId(as: updatedObject) else {
                      return updatedObject
                  }
            return try updatedObject.merge(with: original)
        }
        return API.Command<V, V>(method: .PATCH,
                                 path: object.endpoint,
                                 body: object,
                                 mapper: mapper)
    }

    // MARK: Fetching ParseObjects
    static func fetch<V>(_ object: V, include: [String]?) throws -> API.Command<V, V> where V: ParseObject {
        guard object.objectId != nil else {
            throw ParseError(code: .missingObjectId,
                             message: "objectId must not be nil")
        }

        var params: [String: String]?
        if let includeParams = include {
            params = ["include": "\(Set(includeParams))"]
        }

        return API.Command<V, V>(
            method: .GET,
            path: object.endpoint,
            params: params
        ) { (data) -> V in
            try ParseCoding.jsonDecoder().decode(V.self, from: data)
        }
    }
}

internal extension API.Command where T: ParseObject {

    // MARK: Batch - Saving, Fetching ParseObjects
    static func batch(commands: [API.Command<T, T>],
                      transaction: Bool) -> RESTBatchCommandType<T> {
        let batchCommands = commands.compactMap { (command) -> API.Command<T, T>? in
            let path = Parse.configuration.mountPath + command.path.urlComponent
            guard let body = command.body else {
                return nil
            }
            return API.Command<T, T>(method: command.method,
                                     path: .any(path),
                                     body: body,
                                     mapper: command.mapper)
        }

        let mapper = { @Sendable (data: Data) -> [Result<T, ParseError>] in

            let decodingType = [BatchResponseItem<BatchResponse>].self
            do {
                let responses = try ParseCoding.jsonDecoder().decode(decodingType, from: data)
                return commands.enumerated().map({ (object) -> (Result<T, ParseError>) in
                    let response = responses[object.offset]
                    if let success = response.success,
                       let body = object.element.body {
                        do {
                            let updatedObject = try success.apply(to: body,
                                                                  method: object.element.method)
                            return .success(updatedObject)
                        } catch {
                            let parseError = error as? ParseError ?? ParseError(swift: error)
                            return .failure(parseError)
                        }
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

        let batchCommand = BatchCommand(requests: batchCommands, transaction: transaction)
        return RESTBatchCommandType<T>(method: .POST, path: .batch, body: batchCommand, mapper: mapper)
    }

    // MARK: Batch - Deleting ParseObjects
    static func batch(commands: [API.NonParseBodyCommand<NoBody, NoBody>],
                      transaction: Bool) -> RESTBatchCommandNoBodyType<NoBody> {
        let commands = commands.compactMap { (command) -> API.NonParseBodyCommand<NoBody, NoBody>? in
            let path = Parse.configuration.mountPath + command.path.urlComponent
            return API.NonParseBodyCommand<NoBody, NoBody>(
                method: command.method,
                path: .any(path), mapper: command.mapper)
        }

        let mapper = { @Sendable (data: Data) -> [(Result<Void, ParseError>)] in

            let decodingType = [BatchResponseItem<NoBody>].self
            do {
                let responses = try ParseCoding.jsonDecoder().decode(decodingType, from: data)
                return responses.enumerated().map({ (object) -> (Result<Void, ParseError>) in
                    let response = responses[object.offset]
                    if response.success != nil {
                        return .success(())
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

        let batchCommand = BatchCommandEncodable(requests: commands, transaction: transaction)
        return RESTBatchCommandNoBodyType<NoBody>(method: .POST, path: .batch, body: batchCommand, mapper: mapper)
    }
}
