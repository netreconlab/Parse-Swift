import Foundation
import ParseSwift

let scoreToFetch = GameScore(objectId: "objectId1")
let score2ToFetch = GameScore(objectId: "objectId2")

Task {
    do {
        let results = try await [scoreToFetch, score2ToFetch].deleteAll()
        
        results.forEach { result in
            switch result {
            case .success:
                print("Successfully deleted score")
            case .failure(let error):
                print("Error deleting: \(error)")
            }
        }
    } catch {
        print("Error in batch delete: \(error)")
    }
}
