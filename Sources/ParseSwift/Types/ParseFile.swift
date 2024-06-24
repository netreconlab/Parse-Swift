import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/**
  A `ParseFile` object representes a file of binary data stored on the Parse server.
  This can be a image, video, or anything else that an application needs to reference in a non-relational way.
 */
public struct ParseFile: Fileable, Savable, Deletable, Hashable, Identifiable {

    internal static var type: String {
        "File"
    }

    internal let type: String = Self.type

    internal var isDownloadNeeded: Bool {
        return cloudURL != nil
            && !isSaved
            && localURL == nil
            && data == nil
    }

    /**
     A computed property that is a unique identifier and makes it easy to use `ParseFile`'s
     as models in MVVM and SwiftUI.
     - note: `id` allows `ParseFile`'s to be used even when they are  not saved.
     - important: `id` will have the same value as `name` when a `ParseFile` is saved.
    */
    public var id: String {
        guard isSaved else {
            guard let cloudURL = cloudURL else {
                guard let localURL = localURL else {
                    guard let data = data else {
                        return name
                    }
                    return "\(name)_\(data)"
                }
                return combineName(with: localURL)
            }
            return combineName(with: cloudURL)
        }
        return name
    }

    /**
      The name of the file.
      Before the file is saved, this is the filename given by the user.
      After the file is saved, that name gets prefixed with a unique identifier.
     */
    public internal(set) var name: String

    /**
     The Parse Server url of the file.
     */
    public internal(set) var url: URL?

    /**
     The local file path.
     */
    public var localURL: URL?

    /**
     The link to the file online that should be fetched before uploading to the Parse Server.
     */
    public var cloudURL: URL?

    /**
     The contents of the file.
     */
    public var data: Data?

    /// The Content-Type header to use for the file.
    public var mimeType: String?

    /// Key value pairs to be stored with the file object.
    public var metadata: [String: String]?

    /// Key value pairs to be stored with the file object.
    public var tags: [String: String]?

    /// A set of header options sent to the server.
    public var options: API.Options = []

    /**
     Creates a file with given data and name.
     - parameter name: The name of the new `ParseFile`. The file name must begin with and
     alphanumeric character, and consist of alphanumeric characters, periods, spaces, underscores,
     or dashes. The default value is **file**.
     - parameter data: The contents of the new `ParseFile`.
     - parameter mimeType: Specify the Content-Type header to use for the file,  for example
     **application/pdf**. The default is nil. If no value is specified the file type will be inferred from the file
     extention of `name`.
     - parameter metadata: Optional key value pairs to be stored with file object
     - parameter tags: Optional key value pairs to be stored with file object
     - note: `metadata` and `tags` are file adapter specific and not supported by all file adapters.
     For more, see details on the
     [S3 adapter](https://github.com/parse-community/parse-server-s3-adapter#adding-metadata-and-tags)
     */
    public init(name: String = "file", data: Data, mimeType: String? = nil,
                metadata: [String: String]? = nil, tags: [String: String]? = nil,
                options: API.Options = []) {
        self.name = name
        self.data = data
        self.mimeType = mimeType
        self.metadata = metadata
        self.tags = tags
        self.options = options
    }

    /**
     Creates a file from a local file path and name.
     - parameter name: The name of the new `ParseFile`. The file name must begin with and
     alphanumeric character, and consist of alphanumeric characters, periods, spaces, underscores,
     or dashes. The default value is **file**.
     - parameter localURL: The local file path of the`ParseFile`.
     - parameter mimeType: Specify the Content-Type header to use for the file,  for example
     **application/pdf**. The default is nil. If no value is specified the file type will be inferred from the file
     extention of `name`.
     - parameter metadata: Optional key value pairs to be stored with file object.
     - parameter tags: Optional key value pairs to be stored with file object.
     - note: `metadata` and `tags` are file adapter specific and not supported by all file adapters.
     For more, see details on the
     [S3 adapter](https://github.com/parse-community/parse-server-s3-adapter#adding-metadata-and-tags).
     */
    public init(name: String = "file", localURL: URL,
                metadata: [String: String]? = nil, tags: [String: String]? = nil,
                options: API.Options = []) {
        self.name = name
        self.localURL = localURL
        self.metadata = metadata
        self.tags = tags
        self.options = options
    }

    /**
     Creates a file from a link online and name.
     - parameter name: The name of the new `ParseFile`. The file name must begin with and
     alphanumeric character, and consist of alphanumeric characters, periods, spaces, underscores,
     or dashes. The default value is **file**.
     - parameter cloudURL: The online link of the`ParseFile`.
     - parameter mimeType: Specify the Content-Type header to use for the file,  for example
     **application/pdf**. The default is nil. If no value is specified the file type will be inferred from the file
     extention of `name`.
     - parameter metadata: Optional key value pairs to be stored with file object.
     - parameter tags: Optional key value pairs to be stored with file object.
     - note: `metadata` and `tags` are file adapter specific and not supported by all file adapters.
     For more, see details on the
     [S3 adapter](https://github.com/parse-community/parse-server-s3-adapter#adding-metadata-and-tags).
     */
    public init(name: String = "file", cloudURL: URL,
                metadata: [String: String]? = nil, tags: [String: String]? = nil,
                options: API.Options = []) {
        self.name = name
        self.cloudURL = cloudURL
        self.metadata = metadata
        self.tags = tags
        self.options = options
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }

    public func isSaved() async throws -> Bool {
        isSaved
    }

    enum CodingKeys: String, CodingKey {
        case url
        case name
        case type = "__type"
    }
}

// MARK: Helper Methods (internal)
extension ParseFile {
    func combineName(with url: URL) -> String {
        "\(name)_\(url)"
    }

    func setDefaultOptions(_ options: API.Options) -> API.Options {
        var options = options
        if let mimeType = mimeType {
            options.insert(.mimeType(mimeType))
        } else {
            options.insert(.removeMimeType)
        }
        if let metadata = metadata {
            options.insert(.metadata(metadata))
        }
        if let tags = tags {
            options.insert(.tags(tags))
        }
        options = options.union(self.options)
        return options
    }

    func checkDownloadsForFile(options: API.Options) async throws -> ParseFile? {
        try await yieldIfNotInitialized()
        var cachePolicy: URLRequest.CachePolicy = Parse.configuration.requestCachePolicy
        var shouldBreak = false
        for option in options {
            switch option {
            case .cachePolicy(let policy):
                cachePolicy = policy
                shouldBreak = true
            default:
                continue
            }
            if shouldBreak {
                break
            }
        }
        switch cachePolicy {
        case .useProtocolCachePolicy, .returnCacheDataElseLoad:
            return try createLocalParseFileIfExists()
        case .returnCacheDataDontLoad:
            return try? createLocalParseFileIfExists()
        default:
            throw ParseError(code: .otherCause,
                             message: "Policy defines to load from remote")
        }
    }

    func createLocalParseFileIfExists() throws -> Self {
        let fileLocation = try ParseFileManager.fileExists(self)
        var mutableFile = self
        mutableFile.localURL = fileLocation
        return mutableFile
    }
}

// MARK: Coding
extension ParseFile {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        url = try values.decodeIfPresent(URL.self, forKey: .url)
        name = try values.decode(String.self, forKey: .name)
    }
}

// MARK: Deleting
extension ParseFile {

    /**
     Deletes the file from the Parse cloud. Completes with `nil` if successful.
     - requires: `.usePrimaryKey` has to be available.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: A block that will be called when file deletes or fails.
     It should have the following argument signature: `(Result<Void, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     */
    public func delete(options: API.Options,
                       callbackQueue: DispatchQueue = .main,
                       completion: @escaping (Result<Void, ParseError>) -> Void) {
        Task {
            var options = options
            options.insert(.usePrimaryKey)
            options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
            options = options.union(self.options)

            await deleteFileCommand().execute(options: options,
                                              callbackQueue: callbackQueue) { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    internal func deleteFileCommand() -> API.Command<Self, NoBody> {
        return API.Command<Self, NoBody>.deleteFile(self)
    }
}

// MARK: Saving
extension ParseFile {
    /**
     Creates a file with given stream *synchronously*. A name will be assigned to it by the server.
     
    **Checking progress**
             
          guard let parseFileURL = URL(string: "https://parseplatform.org/img/logo.svg") else {
            return
          }

          let parseFile = ParseFile(name: "logo.svg", cloudURL: parseFileURL)
          let fetchedFile = try parseFile.fetch(stream: InputStream(fileAtPath: URL("parse.org")!) {
          (_, _, totalWritten, totalExpected) in
            let currentProgess = Double(totalWritten)/Double(totalExpected) * 100
            print(currentProgess)
          }
     
    **Cancelling**
              
           guard let parseFileURL = URL(string: "https://parseplatform.org/img/logo.svg") else {
             return
           }

           let parseFile = ParseFile(name: "logo.svg", cloudURL: parseFileURL)
           let fetchedFile = try parseFile.fetch(stream: InputStream(fileAtPath: URL("parse.org")!){
           (task, _, totalWritten, totalExpected) in
             let currentProgess = Double(totalWritten)/Double(totalExpected) * 100
             //Cancel when data exceeds 10%
             if currentProgess > 10 {
               task.cancel()
               print("task has been cancelled")
             }
             print(currentProgess)
           }
      
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter progress: A block that will be called when file updates it is progress.
     It should have the following argument signature: `(task: URLSessionDownloadTask,
     bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)`.
     - parameter stream: An input file stream.
     - parameter callbackQueue: The queue to return to after synchronous completion.
     Default value of .main.
     - returns: A saved `ParseFile`.
     */
    public func save(options: API.Options = [],
                     stream: InputStream,
                     callbackQueue: DispatchQueue = .main,
                     progress: ((URLSessionTask, Int64, Int64, Int64) -> Void)? = nil,
                     completion: @escaping (ParseError?) -> Void) throws {
        try uploadFileCommand()
            .executeStream(options: setDefaultOptions(options),
                           callbackQueue: callbackQueue,
                           uploadProgress: progress,
                           stream: stream,
                           completion: completion)
    }

    /**
     Creates a file with given data *asynchronously* and executes the given callback block.
     A name will be assigned to it by the server. If the file has not been downloaded, it will automatically
     be downloaded before saved.
    
    **Checking progress**
             
          guard let parseFileURL = URL(string: "https://parseplatform.org/img/logo.svg") else {
            return
          }

          let parseFile = ParseFile(name: "logo.svg", cloudURL: parseFileURL)
          let fetchedFile = try parseFile.save { (_, _, totalWritten, totalExpected) in
            let currentProgess = Double(totalWritten)/Double(totalExpected) * 100
            print(currentProgess)
          }
     
    **Cancelling**
              
           guard let parseFileURL = URL(string: "https://parseplatform.org/img/logo.svg") else {
             return
           }

           let parseFile = ParseFile(name: "logo.svg", cloudURL: parseFileURL)
           let fetchedFile = try parseFile.save(progress: {(task, _, totalWritten, totalExpected)-> Void in
               let currentProgess = Double(totalWritten)/Double(totalExpected) * 100
                 //Cancel when data exceeds 10%
                 if currentProgess > 10 {
                   task.cancel()
                   print("task has been cancelled")
                 }
                 print(currentProgess)
               }) { result in
                 ...
           })
      
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter progress: A block that will be called when file updates it is progress.
     It should have the following argument signature: `(task: URLSessionDownloadTask,
     bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)`.
     - parameter completion: A block that will be called when file saves or fails.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    public func save(options: API.Options = [],
                     callbackQueue: DispatchQueue = .main,
                     progress: ((URLSessionTask, Int64, Int64, Int64) -> Void)? = nil,
                     completion: @escaping (Result<Self, ParseError>) -> Void) {
        let options = setDefaultOptions(options)
        if isDownloadNeeded {
            fetch(options: options) { result in
                switch result {

                case .success(let fetched):
                    Task {
                        do {
                            try await fetched.uploadFileCommand()
                                .execute(options: options,
                                         callbackQueue: callbackQueue,
                                         uploadProgress: progress,
                                         completion: completion)
                        } catch {
                            let parseError = error as? ParseError ?? ParseError(swift: error)
                            callbackQueue.async {
                                completion(.failure(parseError))
                            }
                        }
                    }
                case .failure(let error):
                    callbackQueue.async {
                        completion(.failure(error))
                    }
                }
            }
        } else {
            Task {
                do {
                    try await uploadFileCommand()
                        .execute(options: options,
                                 callbackQueue: callbackQueue,
                                 uploadProgress: progress,
                                 completion: completion)
                } catch {
                    let parseError = error as? ParseError ?? ParseError(swift: error)
                    callbackQueue.async {
                        completion(.failure(parseError))
                    }
                }
            }
        }

    }

    internal func uploadFileCommand() throws -> API.Command<Self, Self> {
        try API.Command<Self, Self>.uploadFile(self)
    }
}

// MARK: Fetching
extension ParseFile {

    /**
     Fetches a file with given url *asynchronously*.
     
    **Checking progress**
             
          guard let parseFileURL = URL(string: "https://parseplatform.org/img/logo.svg") else {
            return
          }

          let parseFile = ParseFile(name: "logo.svg", cloudURL: parseFileURL)
          let fetchedFile = try parseFile.fetch { (_, _, totalDownloaded, totalExpected) in
            let currentProgess = Double(totalDownloaded)/Double(totalExpected) * 100
            print(currentProgess)
          }
     
    **Cancelling**
              
           guard let parseFileURL = URL(string: "https://parseplatform.org/img/logo.svg") else {
             return
           }

           let parseFile = ParseFile(name: "logo.svg", cloudURL: parseFileURL)
           let fetchedFile = try parseFile.fetch(progress: {(task, _, totalDownloaded, totalExpected)-> Void in
             let currentProgess = Double(totalDownloaded)/Double(totalExpected) * 100
             //Cancel when data exceeds 10%
             if currentProgess > 10 {
               task.cancel()
               print("task has been cancelled")
             }
             print(currentProgess)
           }) { result in
             ...
           }
      
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter progress: A block that will be called when file updates it is progress.
     It should have the following argument signature: `(task: URLSessionDownloadTask,
     bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)`.
     - parameter completion: A block that will be called when file fetches or fails.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    public func fetch(options: API.Options = [],
                      callbackQueue: DispatchQueue = .main,
                      progress: ((URLSessionDownloadTask, Int64, Int64, Int64) -> Void)? = nil,
                      completion: @escaping (Result<Self, ParseError>) -> Void) {
        let options = setDefaultOptions(options)
        Task {
            do {
                guard let file = try await checkDownloadsForFile(options: options) else {
                    throw ParseError(code: .unsavedFileFailure,
                                     message: "File not downloaded")
                }
                callbackQueue.async {
                    completion(.success(file))
                }
            } catch {
                let parseError = error as? ParseError ?? ParseError(swift: error)
                guard parseError.code != .unsavedFileFailure else {
                    callbackQueue.async {
                        completion(.failure(parseError))
                    }
                    return
                }
                await downloadFileCommand()
                    .execute(options: options,
                             callbackQueue: callbackQueue,
                             downloadProgress: progress,
                             completion: completion)
            }
        }
    }

    internal func downloadFileCommand() -> API.Command<Self, Self> {
        return API.Command<Self, Self>.downloadFile(self)
    }
}

// MARK: CustomDebugStringConvertible
extension ParseFile: CustomDebugStringConvertible {
    public var debugDescription: String {
        guard let descriptionData = try? ParseCoding.jsonEncoder().encode(self) else {
            return "()"
        }
        let descriptionString = String(decoding: descriptionData, as: UTF8.self)
        return "\(descriptionString)"
    }
}

// MARK: CustomStringConvertible
extension ParseFile: CustomStringConvertible {
    public var description: String {
        debugDescription
    }
} // swiftlint:disable:this file_length
