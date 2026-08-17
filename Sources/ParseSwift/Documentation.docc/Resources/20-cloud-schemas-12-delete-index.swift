import Foundation
import ParseSwift

// Delete the index when it's no longer needed
gameScoreSchema = gameScoreSchema.deleteIndex("levelIndex")
