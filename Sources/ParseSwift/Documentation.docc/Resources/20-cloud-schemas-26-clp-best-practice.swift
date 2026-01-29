import Foundation
import ParseSwift

// Best practice: Start with restrictive permissions and grant as needed

// ❌ Don't do this - too permissive
let badCLP = ParseCLP(requiresAuthentication: false, publicAccess: true)

// ✅ Do this - restrictive by default
let goodCLP = ParseCLP(requiresAuthentication: true, publicAccess: false)
    .setAccessPublic(true, on: .find)  // Allow public read
    .setAccessPublic(true, on: .get)   // Allow public get
    // Create, update, and delete require authentication

// ✅ Even better - ownership-based access
let ownershipCLP = ParseCLP(requiresAuthentication: true, publicAccess: false)
    .setAccessPublic(true, on: .find)
    .setPointerFields(Set(["owner"]), on: .get)     // Only owner can get
    .setPointerFields(Set(["owner"]), on: .update)  // Only owner can update
    .setPointerFields(Set(["owner"]), on: .delete)  // Only owner can delete

// Use this for user-owned data like profiles, private messages, etc.
let schema = ParseSchema<GameScore>(classLevelPermissions: ownershipCLP)
