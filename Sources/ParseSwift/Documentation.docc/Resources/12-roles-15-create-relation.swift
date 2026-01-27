import Foundation
import ParseSwift

Task {
    do {
        // Get the current user
        let currentUser = try await User.current()
        
        // Access the relation property
        var relation = currentUser.relation
        
        // Create objects to relate
        let score1 = GameScore(points: 53)
        let score2 = GameScore(points: 57)
        
        // Save the scores first
        let savedScores = try await [score1, score2].saveAll()
        
        // Make an array of all scores that were properly saved
        let scores = savedScores.compactMap { try? $0.get() }
        
        // Add the scores to the relation
        guard let newRelations = try relation?.add("scores", objects: scores) else {
            print("Error: should have unwrapped relation")
            return
        }
        
        // Save the relation
        try await newRelations.save()
        
        print("The relation saved successfully")
        print("Check \"scores\" field in your \"_User\" class in Parse Dashboard.")
    } catch {
        print("Error creating relation: \(error)")
    }
}
