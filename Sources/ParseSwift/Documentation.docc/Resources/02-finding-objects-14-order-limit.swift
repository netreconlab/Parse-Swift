import Foundation
import ParseSwift

let afterDate = Date().addingTimeInterval(-300)

Task {
    do {
        // Combine ordering and limiting for pagination
        let query = GameScore.query("points" > 50,
                                    "createdAt" > afterDate)
            .order([.descending("points")])
            .limit(2)
        
        let results = try await query.find()
        
        print("Top \(results.count) scores:")
        results.forEach { score in
            print("- \(score.points ?? 0) points")
        }
    } catch {
        print("Error querying: \(error)")
    }
}
