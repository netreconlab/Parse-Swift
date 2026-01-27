import Foundation
import ParseSwift

// Create a query just as you normally would
let query = GameScore.query("points" < 11)
print("Created query for GameScore with points < 11")
