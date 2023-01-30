//
//  LiveQuerySocketDelegate.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/4/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//
#if !os(Linux) && !os(Android) && !os(Windows)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

protocol LiveQuerySocketDelegate: AnyObject {
    func status(_ status: LiveQuerySocket.Status,
                closeCode: URLSessionWebSocketTask.CloseCode?,
                reason: Data?) async
    func close() async
    func receivedError(_ error: Error)
    func receivedUnsupported(_ data: Data?, socketMessage: URLSessionWebSocketTask.Message?)
    func received(challenge: URLAuthenticationChallenge,
                  completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    func received(_ data: Data) async
    #if !os(watchOS)
    func received(_ metrics: URLSessionTaskTransactionMetrics)
    #endif
}
#endif
