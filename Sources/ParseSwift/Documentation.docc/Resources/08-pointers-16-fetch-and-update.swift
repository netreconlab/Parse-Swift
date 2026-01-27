import Foundation
import ParseSwift

// Assume we have a saved author
var savedAuthor = Author(name: "Scott", book: Book(title: "world"))
// savedAuthor has been saved and has an objectId

do {
    // Fetch the latest version of the author
    var fetchedAuthor = try await savedAuthor.fetch()
    print("Fetched latest author: \(fetchedAuthor)")
    
    // Update and save
    fetchedAuthor.name = "R.L. Stine"
    
    let results = try await [fetchedAuthor].saveAll()
    
    for result in results {
        switch result {
        case .success(let updatedAuthor):
            print("Updated author: \(updatedAuthor)")
        case .failure(let error):
            print("Error in batch: \(error)")
        }
    }
} catch {
    print("Error: \(error)")
}
