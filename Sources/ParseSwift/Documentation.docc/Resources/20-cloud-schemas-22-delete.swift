import Foundation
import ParseSwift

// Delete the schema entirely (only works if no data exists)
// Note: You must purge the schema first if it contains data
Task {
    do {
        try await gameScoreSchema.delete()
        print("The schema has been deleted.")
        print("The GameScore class no longer exists on Parse Server.")
    } catch {
        print("Could not delete the schema: \(error)")
        print("Make sure the schema contains no data before deleting.")
    }
}
