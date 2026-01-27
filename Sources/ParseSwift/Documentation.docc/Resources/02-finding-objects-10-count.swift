import Foundation
import ParseSwift

let afterDate = Date().addingTimeInterval(-300)
var query = GameScore.query("points" > 50,
                            "createdAt" > afterDate)
    .order([.descending("points")])

Task {
    do {
        // Get the count of matching objects without fetching the data
        let count = try await query.count()
        print("Found total of \(count) GameScore(s)")
    } catch {
        print("Error counting objects: \(error)")
    }
}
