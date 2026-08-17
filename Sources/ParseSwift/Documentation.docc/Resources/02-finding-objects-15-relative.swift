import Foundation
import ParseSwift

Task {
    do {
        // Query for objects created in the next 10 minutes
        let queryRelative = GameScore.query(relative("createdAt" < "in 10 minutes"))

        let results = try await queryRelative.find()
        print("Found \(results.count) GameScore(s) using relative time")

        results.forEach { score in
            if let createdAt = score.createdAt {
                print("Score: \(score.points ?? 0), created at: \(createdAt)")
            }
        }
    } catch {
        print("Error querying with relative time: \(error)")
    }
}
