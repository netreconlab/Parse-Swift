import Foundation
import ParseSwift

// Create the schema on Parse Server
Task {
    do {
        let savedSchema = try await gameScoreSchema.create()
        print("Schema created successfully!")
        print("Check the Parse Dashboard to see your new GameScore class.")
        print("Created schema: \(savedSchema)")
    } catch {
        print("Could not create schema: \(error)")
    }
}
