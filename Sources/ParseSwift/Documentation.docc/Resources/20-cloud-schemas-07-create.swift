import Foundation
import ParseSwift

// Create the schema on Parse Server
gameScoreSchema.create { result in
    switch result {
    case .success(let savedSchema):
        print("Schema created successfully!")
        print("Check the Parse Dashboard to see your new GameScore class.")
        print("Created schema: \(savedSchema)")
    case .failure(let error):
        print("Could not create schema: \(error)")
    }
}
