//
//  ParseURLSessionDelegate.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/4/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

class ParseURLSessionDelegate: NSObject, @unchecked Sendable {
	private let lock = NSLock()
    var callbackQueue: DispatchQueue
    var authentication: (@Sendable (URLAuthenticationChallenge,
                          (URLSession.AuthChallengeDisposition,
                           URLCredential?) -> Void) -> Void)?
    var streamDelegates = [URLSessionTask: InputStream]()

    actor SessionDelegate {
        var downloadDelegates = [
			URLSessionDownloadTask: (@Sendable (URLSessionDownloadTask, Int64, Int64, Int64) -> Void)
		]()
        var uploadDelegates = [URLSessionTask: (@Sendable (URLSessionTask, Int64, Int64, Int64) -> Void)]()
        var taskCallbackQueues = [URLSessionTask: DispatchQueue]()

        func updateDownload(_ task: URLSessionDownloadTask,
                            callback: (@Sendable (URLSessionDownloadTask, Int64, Int64, Int64) -> Void)?) {
            downloadDelegates[task] = callback
        }

        func removeDownload(_ task: URLSessionDownloadTask) {
            downloadDelegates.removeValue(forKey: task)
            taskCallbackQueues.removeValue(forKey: task)
        }

        func updateUpload(_ task: URLSessionTask,
                          callback: (@Sendable (URLSessionTask, Int64, Int64, Int64) -> Void)?) {
            uploadDelegates[task] = callback
        }

        func removeUpload(_ task: URLSessionTask) {
            uploadDelegates.removeValue(forKey: task)
            taskCallbackQueues.removeValue(forKey: task)
        }

        func updateTask(_ task: URLSessionTask,
                        queue: DispatchQueue) {
            taskCallbackQueues[task] = queue
        }

        func removeTask(_ task: URLSessionTask) {
            taskCallbackQueues.removeValue(forKey: task)
        }
    }

    var delegates = SessionDelegate()

    init (callbackQueue: DispatchQueue,
          authentication: (@Sendable (URLAuthenticationChallenge,
                            (URLSession.AuthChallengeDisposition,
                             URLCredential?) -> Void) -> Void)?) {
        self.callbackQueue = callbackQueue
        self.authentication = authentication
        super.init()
    }
}

extension ParseURLSessionDelegate: URLSessionDelegate {
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition,
                                                  URLCredential?) -> Void) {
        if let authentication = authentication {
            callbackQueue.async {
                authentication(challenge, completionHandler)
            }
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

extension ParseURLSessionDelegate: URLSessionDataDelegate {
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didSendBodyData bytesSent: Int64,
                    totalBytesSent: Int64,
                    totalBytesExpectedToSend: Int64) {
        Task {
            if let callback = await delegates.uploadDelegates[task],
               let queue = await delegates.taskCallbackQueues[task] {
                queue.async {
                    callback(task, bytesSent, totalBytesSent, totalBytesExpectedToSend)
                }
            }
        }
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
		lock.lock()
		defer { lock.unlock() }
        if let stream = streamDelegates[task] {
            completionHandler(stream)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		lock.lock()
		defer { lock.unlock() }
        streamDelegates.removeValue(forKey: task)
		Task { [weak self] in
			guard let self else { return }
			await self.delegates.removeUpload(task)
            if let downloadTask = task as? URLSessionDownloadTask {
				await self.delegates.removeDownload(downloadTask)
            }
        }
    }
}

extension ParseURLSessionDelegate: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        Task {
            if let callback = await delegates.downloadDelegates[downloadTask],
               let queue = await delegates.taskCallbackQueues[downloadTask] {
                queue.async {
                    callback(downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
                }
            }
        }
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        Task {
            await delegates.removeDownload(downloadTask)
        }
    }
}
