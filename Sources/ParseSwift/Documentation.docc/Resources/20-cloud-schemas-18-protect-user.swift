import Foundation
import ParseSwift

// Protect the "level" field from users in the "rivals" array
// Users referenced in the "rivals" field will NOT be able to see the "level" field
var protectedCLP = gameScoreSchema.classLevelPermissions
protectedCLP = protectedCLP?
    .setProtectedFieldsPublic(["owner"])
    .setProtectedFields(["level"], userField: "rivals")
gameScoreSchema.classLevelPermissions = protectedCLP
