import Foundation
import ParseSwift

let afterDate = Date().addingTimeInterval(-300)

Task {
    do {
        // Limit results to only 2 objects
        let query = GameScore.query("points" > 50,
                                    "createdAt" > afterDate)
            .order([.descending("points")])
            .limit(2)
        
        let results = try await query.find()
        print("Found \(results.count) GameScore(s) (limited to 2)")
    } catch {
        print("Error querying: \(error)")
    }
}
