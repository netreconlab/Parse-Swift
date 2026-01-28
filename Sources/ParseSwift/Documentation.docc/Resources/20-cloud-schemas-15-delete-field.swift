import Foundation
import ParseSwift

// Remove the "data" field since it's not being used
gameScoreSchema = gameScoreSchema.deleteField("data")
