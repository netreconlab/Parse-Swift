import Foundation
import ParseSwift

// Create a new query for GameScore objects with points > 50
var query2 = GameScore.query("points" > 50)

// Select the fields you are interested in receiving
query2.select("points")
print("Created query with field selection")
