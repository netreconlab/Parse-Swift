import Foundation
import ParseSwift

Task {
    do {
        // Query for scores where name is null or undefined
        let query = GameScore.query(isNull(key: "name"))
        let results = try await query.find()

        print("Found \(results.count) scores with null or undefined name")
        results.forEach { score in
            print("Score: \(score.objectId ?? ""), name is null/undefined")
        }
        // This includes objects where name is null or doesn't exist
    } catch {
        print("Error querying: \(error)")
    }
}
