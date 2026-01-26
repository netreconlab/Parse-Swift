import Foundation
import ParseSwift

// Create a GameScore with a custom ACL
let score = GameScore(points: 100)

Task {
    do {
        // The default ACL will be automatically applied when saved
        let savedScore = try await score.save()
        
        print("Saved score with ACL: \(savedScore)")
        print("Score has ACL: \(savedScore.ACL != nil)")
    } catch {
        print("Error saving score: \(error)")
    }
}
