import Foundation
import ParseSwift

Task {
    // Create and save a new object to the schema
    var gameScore = GameScore()
    gameScore.points = 120
    gameScore.owner = try? await User.current()

    gameScore.save { result in
        switch result {
        case .success(let savedGameScore):
            print("Object saved successfully!")
            print("Saved GameScore: \(savedGameScore)")
        case .failure(let error):
            print("Could not save object: \(error)")
        }
    }
}
