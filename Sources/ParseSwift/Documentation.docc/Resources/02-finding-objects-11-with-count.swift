import Foundation
import ParseSwift

let afterDate = Date().addingTimeInterval(-300)
var query = GameScore.query("points" > 50,
                            "createdAt" > afterDate)
    .order([.descending("points")])

Task {
    do {
        // Get both the results and the total count
        let (scores, count) = try await query.withCount()

        print("Found \(scores.count) GameScore(s) in this page")
        print("Total matching objects: \(count)")

        scores.forEach { score in
            print("Score: \(score.points ?? 0) points")
        }
    } catch {
        print("Error querying with count: \(error)")
    }
}
