//
//  Objectable.swift
//  ParseSwift
//
//  Created by Corey Baker on 10/4/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

/// The base protocol for a `ParseObject`.
/// - note: You should not use this directly and instead use `ParseObject`.
public protocol Objectable: ParseEncodable, Decodable {
    /**
    The class name of the object.
    */
    static var className: String { get }

    /**
    The id of the object.
    */
    var objectId: String? { get set }

    /**
    When the object was created.
    */
    var createdAt: Date? { get set }

    /**
    When the object was last updated.
    */
    var updatedAt: Date? { get set }

    /**
    The ACL for this object.
    */
    var ACL: ParseACL? { get set }

    /**
     The Parse Server endpoint for this object.
     */
    var endpoint: API.Endpoint { get }

    /**
     The Parse Server endpoint for this object.
     - returns: Returns the `API.Endpoint` for this object.
     - throws: An error of `ParseError` type.
     */
    func endpoint(_ method: API.Method) async throws -> API.Endpoint

    /**
     Specifies if this object has been saved.
     - returns: Returns **true** if this object is saved, **false** otherwise.
     - throws: An error of `ParseError` type.
     */
    func isSaved() async throws -> Bool

    /**
     Determines if two objects have the same objectId.
     - parameter as: Object to compare.
     - returns: Returns **true** if the other object has the same `objectId` or **false** if unsuccessful.
    */
    func hasSameObjectId<T: Objectable>(as other: T) -> Bool
}

// MARK: Default Implementation
public extension Objectable {

    static var className: String {
        let classType = "\(type(of: self))"
        return classType.components(separatedBy: ".").first ?? "" // strip .Type
    }

    var className: String {
        Self.className
    }

    var endpoint: API.Endpoint {
        if let objectId = objectId {
            return .object(className: className, objectId: objectId)
        }
        return .objects(className: className)
    }

    func isSaved() async throws -> Bool {
        try await yieldIfNotInitialized()
        if !Parse.configuration.isRequiringCustomObjectIds {
            return objectId != nil
        } else {
            return objectId != nil &&
            createdAt != nil
        }
    }

    func hasSameObjectId<T: Objectable>(as other: T) -> Bool {
        other.className == className &&
        other.objectId == objectId &&
        objectId != nil
    }

    func endpoint(_ method: API.Method) async throws -> API.Endpoint {
        try await yieldIfNotInitialized()
        if !Parse.configuration.isRequiringCustomObjectIds ||
            method != .POST {
            return endpoint
        } else {
            return .objects(className: className)
        }
    }
}

// MARK: Convenience
extension Objectable {

    static func createHash(_ object: Encodable) throws -> String {
        let encoded = try ParseCoding.parseEncoder().encode(object,
                                                            acl: nil,
                                                            batching: false)
        guard let hashString = String(data: encoded, encoding: .utf8) else {
            throw ParseError(code: .otherCause, message: "Could not create hash")
        }
        return hashString
    }

    /// Specifies if a `ParseObject` has been saved.
    /// - warning: This will not be available in ParseSwift 6.0.0. Use `isSaved()` instead.
    /// BAKER mark this internal.
    public var isSaved: Bool {
        if !Parse.configuration.isRequiringCustomObjectIds {
            return objectId != nil
        } else {
            return objectId != nil &&
            createdAt != nil
        }
    }

    func toPointer() throws -> PointerType {
        try PointerType(self)
    }
}

internal struct BaseObjectable: Objectable {
    var objectId: String?

    var createdAt: Date?

    var updatedAt: Date?

    var ACL: ParseACL?
}
