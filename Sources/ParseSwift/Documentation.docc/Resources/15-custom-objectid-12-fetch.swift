import Foundation
import ParseSwift

// Create a GameScore instance with just the custom objectId
let scoreToFetch = GameScore(objectId: "myObjectId", points: 0)

Task {
    do {
        // Fetch the complete object from the server
        let fetchedScore = try await scoreToFetch.fetch()

        print("Successfully fetched: \(fetchedScore)")
        print("ObjectId: \(fetchedScore.objectId ?? "nil")")
        print("Points: \(fetchedScore.points ?? 0)")
    } catch {
        print("Error fetching: \(error)")
    }
}
