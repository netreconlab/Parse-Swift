import Foundation
import ParseSwift

Task {
    do {
        // Query for scores where name exists (is not undefined)
        let query = GameScore.query(exists(key: "name"))
        let results = try await query.find()
        
        print("Found \(results.count) scores with name field")
        results.forEach { score in
            print("Score: \(score.objectId ?? ""), name: \(score.name ?? "null")")
        }
        // This includes objects where name is null or has a value
    } catch {
        print("Error querying: \(error)")
    }
}
