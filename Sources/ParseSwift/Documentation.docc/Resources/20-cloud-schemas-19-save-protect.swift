import Foundation
import ParseSwift

// Update the schema with protected field settings
Task {
    do {
        let updatedSchema = try await gameScoreSchema.update()
        print("Field protection updated successfully!")
        print("Protected fields are now enforced.")
        print("Updated schema: \(updatedSchema)")
        gameScoreSchema = updatedSchema
    } catch {
        print("Could not update schema: \(error)")
    }
}
