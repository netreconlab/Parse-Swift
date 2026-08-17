import Foundation
import ParseSwift

// Index fields that are frequently used in queries

// ✅ Good - index fields used in where clauses
var schema = ParseSchema<GameScore>()
    .addIndex("userIndex", field: "owner", index: 1)      // Queried often
    .addIndex("levelIndex", field: "level", index: 1)     // Used in sorting
    .addIndex("pointsIndex", field: "points", index: -1)  // Descending sort

// Common indexing scenarios:
// 1. Foreign keys (pointer fields) - almost always index these
// 2. Fields used in sorting operations
// 3. Fields frequently used in where clauses
// 4. Fields used in geospatial queries (GeoPoint)

// ❌ Don't over-index
// - Don't index rarely-queried fields
// - Don't index fields with low cardinality (few unique values)
// - Indexes slow down writes, so use them strategically

// For compound queries, consider compound indexes:
// schema.addIndex("userLevelIndex", field: "owner", index: 1)
//       .addIndex("userLevelIndex", field: "level", index: 1)
