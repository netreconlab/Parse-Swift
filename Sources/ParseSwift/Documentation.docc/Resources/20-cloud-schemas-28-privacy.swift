import Foundation
import ParseSwift

// Protect sensitive user data with field-level permissions

// Your specific User value type.
struct User: ParseUser {
    // These are required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    // These are required by ParseUser
    var username: String?
    var email: String?
    var emailVerified: Bool?
    var password: String?
    var authData: [String: [String: String]?]?
}

// Example: User profile with private information
struct UserProfile: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    var displayName: String?      // Public
    var email: String?            // Private - hidden from public, visible to authenticated users
    var phoneNumber: String?      // Private - hidden from public, visible to authenticated users
    var friends: [User]?          // Array of user references
}

// Create schema with field protection
let clp = ParseCLP(requiresAuthentication: true, publicAccess: false)
    .setAccessPublic(true, on: .find)
    .setAccessPublic(true, on: .get)

var profileSchema = ParseSchema<UserProfile>(classLevelPermissions: clp)
    .addField("displayName", type: .string,
             options: ParseFieldOptions<String>(required: true, defauleValue: nil))
    .addField("email", type: .string,
             options: ParseFieldOptions<String>(required: true, defauleValue: nil))
    .addField("phoneNumber", type: .string,
             options: ParseFieldOptions<String>(required: false, defauleValue: nil))

// Protect sensitive fields
var protectedCLP = clp
    .setProtectedFieldsPublic(["email", "phoneNumber"])  // Hide from public

profileSchema.classLevelPermissions = protectedCLP

// This ensures GDPR compliance and user privacy
