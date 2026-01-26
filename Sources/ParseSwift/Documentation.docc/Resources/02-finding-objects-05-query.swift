import Foundation
import ParseSwift

// Create a date 5 minutes in the past
let afterDate = Date().addingTimeInterval(-300)

// Build a query with multiple constraints
// This finds GameScore objects where points > 50 AND createdAt > afterDate
var query = GameScore.query("points" > 50,
                            "createdAt" > afterDate)
    .order([.descending("points")])

print("Query created with constraints: points > 50 and createdAt > \(afterDate)")
