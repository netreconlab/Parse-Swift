import Foundation
import ParseSwift

let afterDate = Date().addingTimeInterval(-300)
var query = GameScore.query("points" > 50,
                            "createdAt" > afterDate)
    .order([.descending("points")])

Task {
    do {
        // Exclude the "points" field
        let queryExclude = query.exclude("points")
        let firstScore = try await queryExclude.first()
        
        // All fields except "points" are populated
        print("Score retrieved (points excluded)")
        print("points is nil: \(firstScore.points == nil)")
        print("oldScore: \(firstScore.oldScore ?? 0)")
    } catch {
        print("Error querying with exclude: \(error)")
    }
}
