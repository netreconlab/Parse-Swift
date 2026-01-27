import Foundation
import ParseSwift

// Attempt to fetch a ParseObject that is not saved
let nonExistentScore = GameScore(objectId: "hello", points: 0)

Task {
    do {
        // Try to fetch the non-existent object
        let fetchedScore = try await nonExistentScore.fetch()
        
        print("Successfully fetched: \(fetchedScore)")
    } catch {
        // Handle the error appropriately
        print("Error fetching (expected): \(error)")
        // The error indicates the object doesn't exist on the server
    }
}
