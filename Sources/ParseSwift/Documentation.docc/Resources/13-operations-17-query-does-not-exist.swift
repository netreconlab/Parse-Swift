import Foundation
import ParseSwift

Task {
    do {
        // Query for scores where name does not exist (is undefined)
        let query = GameScore.query(doesNotExist(key: "name"))
        let results = try await query.find()

        print("Found \(results.count) scores without name field")
        results.forEach { score in
            print("Score: \(score.objectId ?? ""), no name field")
        }
        // This only includes objects where the field was never set or was unset
    } catch {
        print("Error querying: \(error)")
    }
}
