import Foundation
import ParseSwift

let afterDate = Date().addingTimeInterval(-300)
var query = GameScore.query("points" > 50,
                            "createdAt" > afterDate)
    .order([.descending("points")])

Task {
    do {
        let firstScore = try await query.first()

        // Verify the object has expected properties
        guard let objectId = firstScore.objectId,
              let createdAt = firstScore.createdAt else {
            print("Missing required fields")
            return
        }

        print("First score objectId: \(objectId)")
        print("Points: \(firstScore.points ?? 0)")
        print("Created at: \(createdAt)")
    } catch {
        print("Error finding first object: \(error)")
    }
}
