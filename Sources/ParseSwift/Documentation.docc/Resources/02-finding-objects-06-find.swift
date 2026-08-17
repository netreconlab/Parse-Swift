import Foundation
import ParseSwift

let afterDate = Date().addingTimeInterval(-300)
var query = GameScore.query("points" > 50,
                            "createdAt" > afterDate)
    .order([.descending("points")])

Task {
    do {
        // Execute the query to find all matching objects
        let results = try await query.find()
        print("Found \(results.count) GameScore(s)")
    } catch {
        print("Error finding objects: \(error)")
    }
}
