import Foundation
import ParseSwift

let score = GameScore(points: 10)
let score2 = GameScore(points: 3)

Task {
    do {
        let results = try await [score, score2].saveAll()
        
        results.forEach { result in
            switch result {
            case .success(let savedScore):
                print("Saved \"\(savedScore.className)\" with points \(savedScore.points ?? 0)")
            case .failure(let error):
                print("Error saving: \(error)")
            }
        }
    } catch {
        print("Error in batch save: \(error)")
    }
}
