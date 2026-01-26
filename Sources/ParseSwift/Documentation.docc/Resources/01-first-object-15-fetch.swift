import Foundation
import ParseSwift

let scoreToFetch = GameScore(objectId: "someObjectId123")

Task {
    do {
        let fetchedScore = try await scoreToFetch.fetch()
        print("Successfully fetched: \(fetchedScore)")
    } catch {
        print("Error fetching: \(error)")
    }
}
