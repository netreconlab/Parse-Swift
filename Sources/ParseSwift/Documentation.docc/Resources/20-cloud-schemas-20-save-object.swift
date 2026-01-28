import Foundation
import ParseSwift

// Note: This builds on the User and GameScore definitions from previous code samples

Task {
    do {
        // Create and save a new object to the schema
        var gameScore = GameScore()
        gameScore.points = 120
        gameScore.owner = try? await User.current()

        let savedGameScore = try await gameScore.save()
        print("Object saved successfully!")
        print("Saved GameScore: \(savedGameScore)")
    } catch {
        print("Could not save object: \(error)")
    }
}
