import Foundation
import ParseSwift

// Assume we have a saved score with an objectId
let existingObjectId = "someObjectId123"

// Create a GameScore instance with just an objectId
let scoreToFetch = GameScore(objectId: existingObjectId)
