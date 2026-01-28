import Foundation
import ParseSwift

// Add an index on the "level" field for faster queries
// The index value of 1 means ascending order, -1 would be descending
gameScoreSchema = gameScoreSchema.addIndex("levelIndex", field: "level", index: 1)
