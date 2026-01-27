import Foundation
import ParseSwift

Task {
    do {
        // First create and save a score
        let score = GameScore(points: 102, name: "player1")
        let savedScore = try await score.save()
        
        // Create an increment operation to increase points by 1
        let incrementOperation = savedScore
            .operation
            .increment("points", by: 1)
        
        print("Created increment operation for points")
    } catch {
        print("Error: \(error)")
    }
}
