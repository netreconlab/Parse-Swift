import Foundation
import ParseSwift

let scoreToDelete = GameScore(objectId: "objectId1")
let score2ToDelete = GameScore(objectId: "objectId2")

Task {
    do {
        let results = try await [scoreToDelete, score2ToDelete].deleteAll()

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
