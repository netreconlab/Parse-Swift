import Foundation
import ParseSwift

// Create a GameScore
let score = GameScore(points: 10)

Task {
    do {
        // Save with context data that will be available in server-side hooks
        let savedScore = try await score.save(options: [.context(["hello": "world"])])
        
        print("Successfully saved \(savedScore)")
        // The context data is available in beforeSave/afterSave hooks on the server
    } catch {
        print("Error saving: \(error)")
    }
}
