import Foundation
import ParseSwift

Task {
    let score3 = GameScore(points: 30)
    
    do {
        let scoreToDelete = try await score3.save()
        print("Successfully saved: \(scoreToDelete)")
    } catch {
        print("Error saving: \(error)")
    }
}
