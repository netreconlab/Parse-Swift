import Foundation
import ParseSwift

Task {
    let score = GameScore(points: 10)
    let savedScore = try await score.save()
    
    // To modify, you need to make it a var as the value type
    // was initialized as immutable. Using `.mergeable`
    // allows you to only send the updated keys to the
    // parse server as opposed to the whole object
    var changedScore = savedScore.mergeable
    changedScore.points = 200
}
