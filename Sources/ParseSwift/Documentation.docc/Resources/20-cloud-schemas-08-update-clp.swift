import Foundation
import ParseSwift

// Update CLP to only allow access to users specified in the "owner" field
// This means only the owner can perform get operations on their objects
let updatedCLP = clp.setPointerFields(Set(["owner"]), on: .get)
gameScoreSchema.classLevelPermissions = updatedCLP
