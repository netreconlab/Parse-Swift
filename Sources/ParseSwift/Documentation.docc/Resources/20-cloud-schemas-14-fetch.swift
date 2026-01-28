import Foundation
import ParseSwift

// Fetch the current schema from Parse Server
gameScoreSchema.fetch { result in
    switch result {
    case .success(let fetchedSchema):
        print("Schema fetched successfully!")
        print("Fetched schema: \(fetchedSchema)")
        gameScoreSchema = fetchedSchema
    case .failure(let error):
        print("Could not fetch schema: \(error)")
    }
}
