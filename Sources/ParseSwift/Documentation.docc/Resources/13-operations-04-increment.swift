import Foundation
import ParseSwift

// Assuming you have a saved score from the previous step
let savedScore: GameScore // ... previously saved

// Create an increment operation to increase points by 1
let incrementOperation = savedScore
    .operation
    .increment("points", by: 1)

print("Created increment operation for points")
