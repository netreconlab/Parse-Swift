import Foundation
import ParseSwift

// Create a query to find an object by its custom objectId
let query = GameScore.query("objectId" == "myObjectId")

Task {
    do {
        // Execute the query to find the first matching object
        let foundScore = try await query.first()

        print("Found score: \(foundScore)")
        print("ObjectId: \(foundScore.objectId ?? "nil")")
    } catch {
        print("Error querying: \(error)")
    }
}
