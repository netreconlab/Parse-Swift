//
//  SocketTasks.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/29/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

#if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

actor SocketTasks {
    var delegates = [URLSessionWebSocketTask: LiveQuerySocketDelegate]()
    var receivers = [URLSessionWebSocketTask: Bool]()
}

// MARK: Delegates
extension SocketTasks {
    func getDelegates() -> [URLSessionWebSocketTask: LiveQuerySocketDelegate] {
        delegates
    }

    func updateDelegates(_ delegates: [URLSessionWebSocketTask: LiveQuerySocketDelegate]) {
        for (url, function) in delegates {
            self.delegates[url] = function
        }
    }

    func removeDelegates(_ webSocketTasks: [URLSessionWebSocketTask]) {
        for webSocketTask in webSocketTasks {
            self.delegates.removeValue(forKey: webSocketTask)
        }
    }

    func removeAllDelegates() {
        self.delegates.removeAll()
    }
}

// MARK: Receivers
extension SocketTasks {

    func getReceivers() -> [URLSessionWebSocketTask: Bool] {
        receivers
    }

    func updateReceivers(_ receivers: [URLSessionWebSocketTask: Bool]) {
        for (url, receiver) in receivers {
            self.receivers[url] = receiver
        }
    }

    func removeReceivers(_ webSocketTasks: [URLSessionWebSocketTask]) {
        for webSocketTask in webSocketTasks {
            self.receivers.removeValue(forKey: webSocketTask)
        }
    }

    func removeAllReceivers() {
        self.receivers.removeAll()
    }
}

#endif
