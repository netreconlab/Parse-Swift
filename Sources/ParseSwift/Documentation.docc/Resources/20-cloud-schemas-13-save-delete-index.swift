import Foundation
import ParseSwift

// Update the schema on the server to remove the index
gameScoreSchema.update { result in
    switch result {
    case .success(let updatedSchema):
        print("Index deleted successfully!")
        print("Updated schema: \(updatedSchema)")
        gameScoreSchema = updatedSchema
    case .failure(let error):
        print("Could not update schema: \(error)")
    }
}
