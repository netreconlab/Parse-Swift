import Foundation
import ParseSwift

// Purge all objects from the schema (delete all data, keep structure)
Task {
    do {
        try await gameScoreSchema.purge()
        print("All objects have been purged from this schema.")
        print("The schema structure remains intact.")
    } catch {
        print("Could not purge schema: \(error)")
    }
}
