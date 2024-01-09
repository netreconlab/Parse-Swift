import Foundation

private func getObjectId(target: Objectable) throws -> String {
    guard let objectId = target.objectId else {
        throw ParseError(code: .missingObjectId, message: "Cannot set a pointer to an unsaved object")
    }
    return objectId
}

/// A Pointer referencing a ParseObject.
public struct Pointer<T: ParseObject>: ParsePointerObject {

    public typealias Object = T
    public let __type: String = "Pointer" // swiftlint:disable:this identifier_name

    /**
     The class name of the object.
    */
    public var className: String

    /**
     The id of the object.
    */
    public var objectId: String

    /**
     Create a Pointer type.
     - parameter target: Object to point to.
     - throws: An error of type `ParseError`.
     */
    public init(_ target: T) throws {
        self.objectId = try getObjectId(target: target)
        self.className = target.className
    }

    /**
     Create a Pointer type.
     - parameter objectId: The id of the object.
     */
    public init(objectId: String) {
        self.className = T.className
        self.objectId = objectId
    }

    /**
     Convert a Pointer to its respective `ParseObject`.
     - returns: A `ParseObject` created from this Pointer.
     */
    public func toObject() -> T {
        var object = T()
        object.objectId = self.objectId
        return object
    }

    private enum CodingKeys: String, CodingKey {
        case __type, objectId, className // swiftlint:disable:this identifier_name
    }
}

internal struct PointerType: ParsePointer, Codable {
    var __type: String = "Pointer" // swiftlint:disable:this identifier_name
    var className: String
    var objectId: String

    init(_ target: Objectable) throws {
        self.objectId = try getObjectId(target: target)
        self.className = target.className
    }
}
