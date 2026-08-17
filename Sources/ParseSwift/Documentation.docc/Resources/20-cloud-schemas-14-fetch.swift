import Foundation
import ParseSwift

// Fetch the current schema from Parse Server
Task {
    do {
        let fetchedSchema = try await gameScoreSchema.fetch()
        print("Schema fetched successfully!")
        print("Fetched schema: \(fetchedSchema)")
        gameScoreSchema = fetchedSchema
    } catch {
        print("Could not fetch schema: \(error)")
    }
}
