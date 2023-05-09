//
//  ParseVersion.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/1/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
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

    /**
     Current version of the SDK.
     
     - returns: Returns the current `ParseVersion`. If there is none, throws an error.
     - throws: An error of `ParseError` type.
     */
    public static func current() async throws -> Self {
        guard let versionInMemory: Self =
                try? await ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentVersion) else {
            // Handle Memory migrations from String to ParseVersion
            guard let versionStringFromMemoryToMigrate: String =
                    try? await ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentVersion),
                    let versionFromMemoryToMigrate = try? ParseVersion(string: versionStringFromMemoryToMigrate) else {
                #if !os(Linux) && !os(Android) && !os(Windows)
                guard let versionFromStorage: Self =
                        try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentVersion) else {
                    // Handle Keychain migrations from String to ParseVersion
                    guard let versionStringFromStorageToMigrate: String =
                            try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentVersion),
                            // swiftlint:disable:next line_length
                            let versionFromStorageToMigrate = try? ParseVersion(string: versionStringFromStorageToMigrate) else {
                        await KeychainStore.createOld()
                        guard let versionStringFromOldKeychainToMigrate: String =
                                try? await KeychainStore.old.get(valueFor: ParseStorage.Keys.currentVersion),
                              // swiftlint:disable:next line_length
                              let versionFromOldKeychainToMigrate = try? ParseVersion(string: versionStringFromOldKeychainToMigrate) else {
                            throw ParseError(code: .otherCause,
                                             message: "There is no current version")
                        }
                        try? await ParseStorage.shared.set(versionFromOldKeychainToMigrate,
                                                           for: ParseStorage.Keys.currentVersion)
                        try? await KeychainStore.shared.set(versionFromOldKeychainToMigrate,
                                                            for: ParseStorage.Keys.currentVersion)
                        return versionFromOldKeychainToMigrate
                    }
                    try? await ParseStorage.shared.set(versionFromStorageToMigrate,
                                                       for: ParseStorage.Keys.currentVersion)
                    try? await KeychainStore.shared.set(versionFromStorageToMigrate,
                                                        for: ParseStorage.Keys.currentVersion)
                    return versionFromStorageToMigrate
                }
                return versionFromStorage
                #else
                throw ParseError(code: .otherCause,
                                 message: "There is no current version")
                #endif
            }
            try? await ParseStorage.shared.set(versionFromMemoryToMigrate,
                                               for: ParseStorage.Keys.currentVersion)
            return versionFromMemoryToMigrate
        }
        return versionInMemory
    }

    internal static func setCurrent(_ newValue: Self?) async throws {
        try? await ParseStorage.shared.set(newValue, for: ParseStorage.Keys.currentVersion)
        #if !os(Linux) && !os(Android) && !os(Windows)
        try? await KeychainStore.shared.set(newValue, for: ParseStorage.Keys.currentVersion)
        #endif
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
         prereleaseName: PrereleaseName?,
         prereleaseVersion: Int?) throws {
        if prereleaseName != nil && prereleaseVersion == nil || prereleaseName == nil && prereleaseVersion != nil {
            throw ParseError(code: .otherCause,
                             // swiftlint:disable:next line_length
                             message: "preleaseName and prereleaseVersion are both required, you cannot have one without the other")
        }
        self.init(major: major, minor: minor, patch: patch)
        self.prereleaseName = prereleaseName
        self.prereleaseVersion = prereleaseVersion
    }

    static func deleteCurrentContainerFromStorage() async {
        try? await ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentVersion)
        #if !os(Linux) && !os(Android) && !os(Windows)
        try? await KeychainStore.shared.delete(valueFor: ParseStorage.Keys.currentVersion)
        #endif
    }

    static func convertVersionString(_ string: String) throws -> Self {
        let splitVersion = string.split(separator: ".")
        if splitVersion.count < 3 {
            throw ParseError(code: .otherCause,
                             message: "Version is in the incorrect format, should be: \"1.1.1\" or \"1.1.1-beta.1\"")
        }
        var major: Int!
        var minor: Int!
        var patch: Int!
        var prereleaseName: PrereleaseName?
        var prereleaseVersion: Int?

        for (index, item) in splitVersion.enumerated() {
            switch index {
            case 0:
                major = try convertToInt(item)
            case 1:
                minor = try convertToInt(item)
            case 2:
                let splitPrerelease = item.split(separator: "-")
                patch = try convertToInt(splitPrerelease[0])
                if splitPrerelease.count > 1 {
                    prereleaseName = PrereleaseName(rawValue: String(splitPrerelease[1]))
                }
            case 3:
                prereleaseVersion = try convertToInt(item)
            default:
                throw ParseError(code: .otherCause,
                                 // swiftlint:disable:next line_length
                                 message: "Version string has too many values, should be: \"1.1.1\" or \"1.1.1-beta.1\"")
            }
        }

        return try Self(major: major,
                        minor: minor,
                        patch: patch,
                        prereleaseName: prereleaseName,
                        prereleaseVersion: prereleaseVersion)
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
public extension ParseVersion {

    /**
     Create an instance from a `String`.
     
     - parameter string: A semver string to convert to a `ParseVersion`.
     - throws: An error of `ParseError` type.
     */
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
        var version = "\(major).\(minor).\(patch)"
        if let prereleaseName = prereleaseName,
           let prereleaseVersion = prereleaseVersion {
            version = "\(version)-\(prereleaseName).\(prereleaseVersion)"
        }
        return version
    }
}
