import Foundation
import ParseSwift

Task {
    do {
        // Query for scores where name is not null
        let query = GameScore.query(isNotNull(key: "name"))
        let results = try await query.find()

        print("Found \(results.count) scores with non-null name")
        results.forEach { score in
            print("Score: \(score.objectId ?? ""), name: \(score.name ?? "error")")
        }
        // This only includes objects where name has an actual value
    } catch {
        print("Error querying: \(error)")
    }
}
