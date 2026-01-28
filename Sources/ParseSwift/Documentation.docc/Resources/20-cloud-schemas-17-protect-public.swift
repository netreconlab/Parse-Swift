import Foundation
import ParseSwift

// Protect the "owner" field from public access
// Public users won't be able to see this field in queries
var protectedCLP = gameScoreSchema.classLevelPermissions
protectedCLP = protectedCLP?.setProtectedFieldsPublic(["owner"])
gameScoreSchema.classLevelPermissions = protectedCLP
