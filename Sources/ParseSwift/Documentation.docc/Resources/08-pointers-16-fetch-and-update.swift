import Foundation
import ParseSwift

do {
    // Create and save the author so it has an objectId
    var savedAuthor = try await Author(name: "Scott", book: Book(title: "world")).save()

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
