import Foundation
import ParseSwift

let afterDate = Date().addingTimeInterval(-300)

Task {
    do {
        // Order results by points in descending order (highest first)
        let query = GameScore.query("points" > 50,
                                    "createdAt" > afterDate)
            .order([.descending("points")])

        let results = try await query.find()

        results.forEach { score in
            print("Score: \(score.points ?? 0) points")
        }
    } catch {
        print("Error querying: \(error)")
    }
}
