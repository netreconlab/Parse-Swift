import Foundation
import ParseSwift

// Create an ACL with role-based permissions
var acl = ParseACL()

// Grant read access to users in the "Administrator" role
acl.setReadAccess(roleName: "Administrator", value: true)

// Grant write access only to users in the "Administrator" role
acl.setWriteAccess(roleName: "Administrator", value: true)

print("ACL created with role-based permissions")
print("Only administrators can read and write this object")
