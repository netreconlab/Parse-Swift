import Foundation
import ParseSwift

// Class-Level Permissions (CLP) control access to Parse classes
// 
// Available operations:
// - .get: Retrieve a single object by objectId
// - .find: Query for objects
// - .create: Create new objects
// - .update: Modify existing objects
// - .delete: Delete objects
// - .addField: Add new fields to the schema
//
// You can set permissions for:
// - Public access (anyone, including unauthenticated users)
// - Authenticated users (requiresAuthentication)
// - Specific users or roles
// - Users referenced in pointer fields
