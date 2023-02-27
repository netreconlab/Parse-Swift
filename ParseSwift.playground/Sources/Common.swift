import Foundation
import ParseSwift

public func initializeParse(customObjectId: Bool = false) async throws {
    try await ParseSwift.initialize(applicationId: "applicationId",
                                    clientKey: "clientKey",
                                    primaryKey: "primaryKey",
                                    serverURL: URL(string: "http://localhost:1337/parse")!,
                                    requiringCustomObjectIds: customObjectId,
                                    usingEqualQueryConstraint: false,
                                    usingDataProtectionKeychain: false)
}
