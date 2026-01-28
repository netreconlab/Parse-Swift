import Foundation
import ParseSwift

// Create a CLP that requires authentication by default
// but allows public read access
let clp = ParseCLP(requiresAuthentication: true, publicAccess: false)
    .setAccessPublic(true, on: .get)
    .setAccessPublic(true, on: .find)
