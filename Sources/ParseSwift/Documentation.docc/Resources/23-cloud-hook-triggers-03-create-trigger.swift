import Foundation
import ParseSwift

// Create a trigger for the GameScore class
let gameScore = GameScore()
var myTrigger = ParseHookTrigger(object: gameScore,
                                 trigger: .afterSave,
                                 url: URL(string: "https://api.example.com/gameScore/afterSave")!)
