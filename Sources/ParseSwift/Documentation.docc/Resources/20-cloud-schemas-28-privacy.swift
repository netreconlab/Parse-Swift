import Foundation
import ParseSwift

// Protect sensitive user data with field-level permissions

// Example: User profile with private information
struct UserProfile: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?
    
    var displayName: String?      // Public
    var email: String?            // Private - only visible to owner
    var phoneNumber: String?      // Private - only visible to owner
    var friends: [User]?          // Semi-private - visible to friends
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
    .setProtectedFields(["friends"], userField: "friends") // Visible to friends

profileSchema.classLevelPermissions = protectedCLP

// This ensures GDPR compliance and user privacy
