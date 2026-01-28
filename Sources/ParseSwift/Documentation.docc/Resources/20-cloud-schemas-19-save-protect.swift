import Foundation
import ParseSwift

// Update the schema with protected field settings
gameScoreSchema.update { result in
    switch result {
    case .success(let updatedSchema):
        print("Field protection updated successfully!")
        print("Protected fields are now enforced.")
        print("Updated schema: \(updatedSchema)")
        gameScoreSchema = updatedSchema
    case .failure(let error):
        print("Could not update schema: \(error)")
    }
}
