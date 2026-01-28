import Foundation
import ParseSwift

// Example: Schema migration pattern
// Always check current state before making changes

Task {
    do {
        // Try to fetch the existing schema
        var schema = try await ParseSchema<GameScore>().fetch()
        print("Schema exists, checking for required updates...")
        
        // Add new field if it doesn't exist
        // The update will fail gracefully if the field already exists
        schema = schema.addField("newField",
                                 type: .string,
                                 options: ParseFieldOptions<String>(required: false,
                                                                    defauleValue: nil))
        
        _ = try await schema.update()
        print("Schema migrated successfully!")
        
    } catch {
        // Schema doesn't exist, create it
        print("Schema doesn't exist, creating new schema...")
        
        let clp = ParseCLP(requiresAuthentication: true, publicAccess: false)
            .setAccessPublic(true, on: .find)
        
        var newSchema = ParseSchema<GameScore>(classLevelPermissions: clp)
            .addField("points", type: .number,
                     options: ParseFieldOptions<Int>(required: false, defauleValue: nil))
        
        _ = try await newSchema.create()
        print("Schema created successfully!")
    }
}
