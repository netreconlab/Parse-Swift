import Foundation
import ParseSwift

// Update the schema on the server to remove the index
Task {
    do {
        let updatedSchema = try await gameScoreSchema.update()
        print("Index deleted successfully!")
        print("Updated schema: \(updatedSchema)")
        gameScoreSchema = updatedSchema
    } catch {
        print("Could not update schema: \(error)")
    }
}
