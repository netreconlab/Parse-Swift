import Foundation
import ParseSwift

Task {
    var score = GameScore()
    score.points = 200
    score.oldScore = 10
    score.isHighest = true

    do {
        let savedScore = try await score.save()
        print("Saved GameScore with objectId: \(savedScore.objectId ?? "unknown")")
    } catch {
        print("Error saving: \(error)")
    }
}
