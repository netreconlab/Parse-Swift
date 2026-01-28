import Foundation
import ParseSwift

// Create a schema with the CLP and add fields
var gameScoreSchema = ParseSchema<GameScore>(classLevelPermissions: clp)
    .addField("points",
              type: .number,
              options: ParseFieldOptions<Int>(required: false, defauleValue: nil))
    .addField("level",
              type: .number,
              options: ParseFieldOptions<Int>(required: false, defauleValue: nil))
    .addField("data",
              type: .bytes,
              options: ParseFieldOptions<String>(required: false, defauleValue: nil))
