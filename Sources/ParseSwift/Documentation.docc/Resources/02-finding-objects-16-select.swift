import Foundation
import ParseSwift

let afterDate = Date().addingTimeInterval(-300)
var query = GameScore.query("points" > 50,
                            "createdAt" > afterDate)
    .order([.descending("points")])

Task {
    do {
        // Select only the "points" field
        let querySelect = query.select("points")
        let firstScore = try await querySelect.first()
        
        // Only the selected field and required Parse fields are populated
        print("Selected score with points: \(firstScore.points ?? 0)")
        // Other custom fields like oldScore will be nil
        print("oldScore is nil: \(firstScore.oldScore == nil)")
    } catch {
        print("Error querying with select: \(error)")
    }
}
