import Foundation
import ParseSwift

let afterDate = Date().addingTimeInterval(-300)
var query = GameScore.query("points" > 50,
                            "createdAt" > afterDate)
    .order([.descending("points")])

Task {
    do {
        // Get just the first matching object
        let firstScore = try await query.first()
        print("Found first GameScore: \(firstScore)")
    } catch {
        print("Error finding first object: \(error)")
    }
}
