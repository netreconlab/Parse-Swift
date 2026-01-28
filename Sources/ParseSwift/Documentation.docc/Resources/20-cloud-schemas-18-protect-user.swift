import Foundation
import ParseSwift

// Protect the "level" field so it's only visible to users in the "rivals" array
// Only users referenced in the "rivals" field can see the "level" field
var protectedCLP = gameScoreSchema.classLevelPermissions
protectedCLP = protectedCLP?
    .setProtectedFieldsPublic(["owner"])
    .setProtectedFields(["level"], userField: "rivals")
gameScoreSchema.classLevelPermissions = protectedCLP
