import Foundation
import ParseSwift

Task {
    var score = GameScore()
    score.points = 200
    score.oldScore = 10
    score.isHighest = true
    
    do {
        let savedScore = try await score.save()
        print("Saved GameScore with objectId: \(savedScore.objectId ?? "unknown")")
    } catch {
        print("Error saving: \(error)")
    }
}

// Create a date 5 minutes in the past
let afterDate = Date().addingTimeInterval(-300)

// Build a query with multiple constraints
var query = GameScore.query("points" > 50,
                            "createdAt" > afterDate)
    .order([.descending("points")])

print("Query created with constraints: points > 50 and createdAt > \(afterDate)")
