import Foundation
import ParseSwift

// Update the schema on the server with the new CLP
Task {
    do {
        let updatedSchema = try await gameScoreSchema.update()
        print("CLP updated successfully!")
        print("Updated schema: \(updatedSchema)")
        // Update the local schema with the server response
        gameScoreSchema = updatedSchema
    } catch {
        print("Could not update schema: \(error)")
    }
}
