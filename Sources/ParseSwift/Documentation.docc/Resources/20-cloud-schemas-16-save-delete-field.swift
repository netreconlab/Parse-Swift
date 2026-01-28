import Foundation
import ParseSwift

// Update the schema on the server to remove the field
Task {
    do {
        let updatedSchema = try await gameScoreSchema.update()
        print("Field deleted successfully!")
        print("The 'data' field has been removed from the schema.")
        print("Updated schema: \(updatedSchema)")
        gameScoreSchema = updatedSchema
    } catch {
        print("Could not update schema: \(error)")
    }
}
