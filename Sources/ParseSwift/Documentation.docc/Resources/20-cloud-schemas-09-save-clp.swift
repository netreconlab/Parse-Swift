import Foundation
import ParseSwift

// Update the schema on the server with the new CLP
gameScoreSchema.update { result in
    switch result {
    case .success(let updatedSchema):
        print("CLP updated successfully!")
        print("Updated schema: \(updatedSchema)")
        // Update the local schema with the server response
        gameScoreSchema = updatedSchema
    case .failure(let error):
        print("Could not update schema: \(error)")
    }
}
