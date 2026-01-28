import Foundation
import ParseSwift

// Available trigger types for database events
let gameScore = GameScore()

let afterSaveTrigger = ParseHookTrigger(object: gameScore,
                                        trigger: .afterSave,
                                        url: URL(string: "https://api.example.com/afterSave")!)

let beforeSaveTrigger = ParseHookTrigger(object: gameScore,
                                         trigger: .beforeSave,
                                         url: URL(string: "https://api.example.com/beforeSave")!)

let afterDeleteTrigger = ParseHookTrigger(object: gameScore,
                                          trigger: .afterDelete,
                                          url: URL(string: "https://api.example.com/afterDelete")!)

let beforeDeleteTrigger = ParseHookTrigger(object: gameScore,
                                           trigger: .beforeDelete,
                                           url: URL(string: "https://api.example.com/beforeDelete")!)

let afterFindTrigger = ParseHookTrigger(object: gameScore,
                                        trigger: .afterFind,
                                        url: URL(string: "https://api.example.com/afterFind")!)

let beforeFindTrigger = ParseHookTrigger(object: gameScore,
                                         trigger: .beforeFind,
                                         url: URL(string: "https://api.example.com/beforeFind")!)
