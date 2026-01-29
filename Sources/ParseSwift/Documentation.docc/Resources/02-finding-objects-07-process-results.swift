import Foundation
import ParseSwift

let afterDate = Date().addingTimeInterval(-300)
var query = GameScore.query("points" > 50,
                            "createdAt" > afterDate)
    .order([.descending("points")])

Task {
    do {
        let results = try await query.find()
        print("Found \(results.count) GameScore(s)")

        // Process each result
        results.forEach { score in
            guard let createdAt = score.createdAt else { return }
            print("Found score: \(score.points ?? 0) points, created at: \(createdAt)")
        }
    } catch {
        print("Error finding objects: \(error)")
    }
}
