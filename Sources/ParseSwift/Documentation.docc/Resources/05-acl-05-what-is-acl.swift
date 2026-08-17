import Foundation
import ParseSwift

// Create a basic ACL
var acl = ParseACL()

// Set public read access (anyone can read)
acl.publicRead = true

// Set public write access (anyone can write)
acl.publicWrite = false

print("ACL created with public read: \(acl.publicRead)")
print("ACL created with public write: \(acl.publicWrite)")
