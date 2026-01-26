import Foundation
import ParseSwift

Task {
    let score3 = GameScore(points: 30)
    let scoreToDelete = try await score3.save()
    
    do {
        try await scoreToDelete.delete()
        print("Successfully deleted: \(scoreToDelete)")
    } catch {
        print("Error deleting: \(error)")
    }
}
