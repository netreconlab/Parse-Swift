//
//  BaseParseInstallation.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/7/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

internal struct BaseParseInstallation: ParseInstallation {
    var deviceType: String?
    var installationId: String?
    var deviceToken: String?
    var badge: Int?
    var timeZone: String?
    var channels: [String]?
    var appName: String?
    var appIdentifier: String?
    var appVersion: String?
    var parseVersion: String?
    var localeIdentifier: String?
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    static func createNewInstallationIfNeeded() async {
        let currentContainer = await Self.currentContainer()
        guard let installationId = currentContainer.installationId,
            currentContainer.currentInstallation?.installationId == installationId else {
            try? await ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentInstallation)
            #if !os(Linux) && !os(Android) && !os(Windows)
            try? await KeychainStore.shared.delete(valueFor: ParseStorage.Keys.currentInstallation)
            #endif
            _ = Self.currentContainer
            return
        }
    }
}
