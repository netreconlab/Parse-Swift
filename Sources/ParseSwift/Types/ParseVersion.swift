//
//  ParseVersion.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/1/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

/// `ParseVersion` is used to determine the version of the SDK. The current
/// version of the SDK is persisted to the Keychain.
public struct ParseVersion: ParseTypeable, Hashable {

    var major: Int
    var minor: Int
    var patch: Int
    var prereleaseName: PrereleaseName?
    var prereleaseVersion: Int?

    /// The string representation of the version.
    public var string: String {
        var version = "\(major).\(minor).\(patch)"
        if let prereleaseName = prereleaseName,
           let prereleaseVersion = prereleaseVersion {
            version = "\(version)-\(prereleaseName).\(prereleaseVersion)"
        }
        return version
    }

    /// Current version of the SDK.
    public internal(set) static var current: Self? {
        get {
            let synchronizationQueue = createSynchronizationQueue("ParseVersion.getCurrent")
            return synchronizationQueue.sync(execute: { () -> Self? in
                guard let versionInMemory: Self =
                        try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentVersion) else {
                    // Handle Memory migrations from String to ParseVersion
                    guard let versionStringFromMemoryToMigrate: String =
                            try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentVersion),
                            // swiftlint:disable:next line_length
                            let versionFromMemoryToMigrate = try? ParseVersion(string: versionStringFromMemoryToMigrate) else {
                        #if !os(Linux) && !os(Android) && !os(Windows)
                        guard let versionFromKeychain: Self =
                                try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentVersion) else {
                            // Handle Keychain migrations from String to ParseVersion
                            guard let versionStringFromKeychainToMigrate: String =
                                    try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentVersion),
                                    // swiftlint:disable:next line_length
                                    let versionFromKeychainToMigrate = try? ParseVersion(string: versionStringFromKeychainToMigrate) else {
                                guard let versionStringFromOldKeychainToMigrate: String =
                                        try? KeychainStore.old.get(valueFor: ParseStorage.Keys.currentVersion),
                                      // swiftlint:disable:next line_length
                                      let versionFromOldKeychainToMigrate = try? ParseVersion(string: versionStringFromOldKeychainToMigrate) else {
                                    return nil
                                }
                                try? KeychainStore.shared.set(versionFromOldKeychainToMigrate,
                                                              for: ParseStorage.Keys.currentVersion)
                                return versionFromOldKeychainToMigrate
                            }
                            try? KeychainStore.shared.set(versionFromKeychainToMigrate,
                                                          for: ParseStorage.Keys.currentVersion)
                            return versionFromKeychainToMigrate
                        }
                        return versionFromKeychain
                        #else
                        return nil
                        #endif
                    }
                    try? ParseStorage.shared.set(versionFromMemoryToMigrate,
                                                 for: ParseStorage.Keys.currentVersion)
                    return versionFromMemoryToMigrate
                }
                return versionInMemory
            })
        }
        set {
            let synchronizationQueue = createSynchronizationQueue("ParseVersion.setCurrent")
            synchronizationQueue.sync {
                try? ParseStorage.shared.set(newValue, for: ParseStorage.Keys.currentVersion)
                #if !os(Linux) && !os(Android) && !os(Windows)
                try? KeychainStore.shared.set(newValue, for: ParseStorage.Keys.currentVersion)
                #endif
            }
        }
    }

    enum PrereleaseName: String, Codable, Comparable {
        case alpha, beta

        static func < (lhs: ParseVersion.PrereleaseName, rhs: ParseVersion.PrereleaseName) -> Bool {
            lhs == .alpha && rhs == .beta
        }

        static func > (lhs: ParseVersion.PrereleaseName, rhs: ParseVersion.PrereleaseName) -> Bool {
            lhs == .beta && rhs == .alpha
        }
    }

    init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    init(major: Int,
         minor: Int,
         patch: Int,
         prereleaseName: PrereleaseName,
         prereleaseVersion: Int) {
        self.init(major: major, minor: minor, patch: patch)
        self.prereleaseName = prereleaseName
        self.prereleaseVersion = prereleaseVersion
    }

    static func deleteCurrentContainerFromKeychain() {
        try? ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentVersion)
        #if !os(Linux) && !os(Android) && !os(Windows)
        try? KeychainStore.shared.delete(valueFor: ParseStorage.Keys.currentVersion)
        #endif
    }

    static func convertVersionString(_ string: String) throws -> Self {
        let splitVersion = string.split(separator: ".")
        if splitVersion.count < 3 {
            throw ParseError(code: .otherCause,
                             message: "Version is in the incorrect format, should be, \"1.1.1\"")
        }
        var major: Int!
        var minor: Int!
        var patch: Int!

        for (index, item) in splitVersion.enumerated() {
            switch index {
            case 0:
                major = try convertToInt(item)
            case 1:
                minor = try convertToInt(item)
            case 2:
                patch = try convertToInt(item)
            default:
                throw ParseError(code: .otherCause,
                                 message: "Version string has too many values")
            }
        }

        return Self(major: major, minor: minor, patch: patch)
    }

    static func convertToInt(_ subSequence: String.SubSequence) throws -> Int {
        guard let integer = Int(subSequence) else {
            throw ParseError(code: .otherCause,
                             message: "Could not convert version to semver")
        }
        return integer
    }
}

// MARK: Default Implementation
extension ParseVersion {
    init(string: String) throws {
        self = try Self.convertVersionString(string)
    }
}

// MARK: Comparable
extension ParseVersion: Comparable {

    // swiftlint:disable:next cyclomatic_complexity
    public static func > (left: Self, right: Self) -> Bool {
        if left.major > right.major {
            return true
        } else if left.major < right.major {
            return false
        } else if left.minor > right.minor {
            return true
        } else if left.minor < right.minor {
            return false
        } else if left.patch > right.patch {
            return true
        } else if left.patch < right.patch {
            return false
        } else if left.prereleaseVersion == nil && right.prereleaseVersion != nil {
            return true
        } else if left.prereleaseVersion != nil && right.prereleaseVersion == nil {
            return false
        } else if let leftPreReleaseName = left.prereleaseName,
                  let rightPreReleaseName = right.prereleaseName,
                  let leftPreReleaseVersion = left.prereleaseVersion,
                  let rightPreReleaseVersion = right.prereleaseVersion {
            if leftPreReleaseName > rightPreReleaseName {
                return true
            } else if leftPreReleaseName < rightPreReleaseName {
                return false
            } else if leftPreReleaseVersion > rightPreReleaseVersion {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }

    public static func >= (left: Self, right: Self) -> Bool {
        guard left == right || left > right else {
            return false
        }
        return true
    }

    // swiftlint:disable:next cyclomatic_complexity
    public static func < (left: Self, right: Self) -> Bool {
        if left.major < right.major {
            return true
        } else if left.major > right.major {
            return false
        } else if left.minor < right.minor {
            return true
        } else if left.minor > right.minor {
            return false
        } else if left.patch < right.patch {
            return true
        } else if left.patch > right.patch {
            return false
        } else if left.prereleaseVersion != nil && right.prereleaseVersion == nil {
            return true
        } else if left.prereleaseVersion == nil && right.prereleaseVersion != nil {
            return false
        } else if let leftPreReleaseName = left.prereleaseName,
                  let rightPreReleaseName = right.prereleaseName,
                  let leftPreReleaseVersion = left.prereleaseVersion,
                  let rightPreReleaseVersion = right.prereleaseVersion {
            if leftPreReleaseName < rightPreReleaseName {
                return true
            } else if leftPreReleaseName > rightPreReleaseName {
                return false
            } else if leftPreReleaseVersion < rightPreReleaseVersion {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }

    public static func <= (left: Self, right: Self) -> Bool {
        guard left == right || left < right else {
            return false
        }
        return true
    }
}

// MARK: CustomDebugStringConvertible
extension ParseVersion {
    public var debugDescription: String {
        string
    }
}
