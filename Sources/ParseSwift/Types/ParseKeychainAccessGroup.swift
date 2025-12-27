//
//  ParseKeychainAccessGroup.swift
//  ParseSwift
//
//  Created by Corey Baker on 8/23/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

#if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
import Foundation

struct ParseKeychainAccessGroup: ParseTypeable {

    var accessGroup: String?
    var isSyncingKeychainAcrossDevices = false

    static func current() async throws -> Self {
        guard let versionInMemory: Self =
                try? await ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentAccessGroup) else {
            guard let versionFromKeyChain: Self =
                    try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentAccessGroup)
            else {
                throw ParseError(code: .otherCause,
                                 message: "There is no current Keychain access group")
            }
            return versionFromKeyChain
        }
        return versionInMemory
    }

    static func setCurrent(_ newValue: Self?) async {
        guard let updatedKeychainAccessGroup = newValue else {
            let defaultKeychainAccessGroup = Self()
            try? await ParseStorage.shared.set(defaultKeychainAccessGroup, for: ParseStorage.Keys.currentAccessGroup)
            try? await KeychainStore.shared.set(defaultKeychainAccessGroup, for: ParseStorage.Keys.currentAccessGroup)
            Parse.configuration.keychainAccessGroup = defaultKeychainAccessGroup
            return
        }
        try? await ParseStorage.shared.set(updatedKeychainAccessGroup, for: ParseStorage.Keys.currentAccessGroup)
        try? await KeychainStore.shared.set(updatedKeychainAccessGroup, for: ParseStorage.Keys.currentAccessGroup)
        Parse.configuration.keychainAccessGroup = updatedKeychainAccessGroup
    }

    static func deleteCurrentContainerFromStorage() async {
        try? await ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentAccessGroup)
        try? await KeychainStore.shared.delete(valueFor: ParseStorage.Keys.currentAccessGroup)
        Parse.configuration.keychainAccessGroup = Self()
    }
}
#endif
