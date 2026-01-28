import Foundation
import ParseSwift

// Purge all objects from the schema (delete all data, keep structure)
gameScoreSchema.purge { result in
    switch result {
    case .success:
        print("All objects have been purged from this schema.")
        print("The schema structure remains intact.")
    case .failure(let error):
        print("Could not purge schema: \(error)")
    }
}
