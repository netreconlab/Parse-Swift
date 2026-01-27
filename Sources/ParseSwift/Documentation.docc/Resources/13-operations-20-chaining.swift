import Foundation
import ParseSwift

// Assuming you have a saved score
let savedScore: GameScore // ... previously saved

// Chain multiple operations together
let combinedOperation = savedScore
    .operation
    .increment("points", by: 10)
    .add("tags", objects: ["featured"])
    .set(("name", \.name), to: "champion")

print("Created combined operation with increment, add, and set")
