import Foundation
import ParseSwift

// Create a query to find an object by its custom objectId
let query = GameScore.query("objectId" == "myObjectId")
