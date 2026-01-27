import Foundation
import ParseSwift

// Attempt to fetch a ParseObject that is not saved
let nonExistentScore = GameScore(objectId: "hello", points: 0)
