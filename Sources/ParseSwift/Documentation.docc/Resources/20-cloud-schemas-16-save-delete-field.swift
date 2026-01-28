import Foundation
import ParseSwift

// Update the schema on the server to remove the field
gameScoreSchema.update { result in
    switch result {
    case .success(let updatedSchema):
        print("Field deleted successfully!")
        print("The 'data' field has been removed from the schema.")
        print("Updated schema: \(updatedSchema)")
        gameScoreSchema = updatedSchema
    case .failure(let error):
        print("Could not update schema: \(error)")
    }
}
