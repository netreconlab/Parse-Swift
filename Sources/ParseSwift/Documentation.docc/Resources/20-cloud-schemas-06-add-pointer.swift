import Foundation
import ParseSwift

// Add pointer and array fields to establish relationships
do {
    gameScoreSchema = try gameScoreSchema
        .addField("owner",
                  type: .pointer,
                  options: ParseFieldOptions<User>(required: false, defauleValue: nil))
        .addField("rivals",
                  type: .array,
                  options: ParseFieldOptions<[User]>(required: false, defauleValue: nil))
} catch {
    print("Error adding pointer fields: \(error)")
}
