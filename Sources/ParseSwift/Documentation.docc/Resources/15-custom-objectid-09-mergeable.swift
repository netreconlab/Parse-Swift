import Foundation
import ParseSwift

Task {
    do {
        let score = GameScore(objectId: "myObjectId", points: 10)
        let savedScore = try await score.save()

        // To modify, need to make it a var as the value type
        // was initialized as immutable. Using .mergeable allows
        // you to only send the updated keys to the server
        var changedScore = savedScore.mergeable
        changedScore.points = 200
    } catch {
        print("Error: \(error)")
    }
}
