import Foundation
import ParseSwift

let scoreToFetch = GameScore(objectId: "objectId1")
let score2ToFetch = GameScore(objectId: "objectId2")

Task {
    do {
        let fetchedScores = try await [scoreToFetch, score2ToFetch].fetchAll()
        
        fetchedScores.forEach { result in
            switch result {
            case .success(let fetched):
                print("Successfully fetched: \(fetched)")
            case .failure(let error):
                print("Error fetching: \(error)")
            }
        }
    } catch {
        print("Error in batch fetch: \(error)")
    }
}
