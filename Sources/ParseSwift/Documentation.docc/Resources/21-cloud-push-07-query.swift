import Foundation
import ParseSwift

// Create a query to target all installations
let installationQuery = Installation.query(isNotNull(key: "objectId"))
