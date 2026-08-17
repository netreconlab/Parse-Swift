import Foundation
import ParseSwift

// Example: Schema creation in a deployment script
// This runs during application deployment, not in the client app

Task {
    do {
        // Initialize Parse with primary key (only in secure server environment)
        try await Parse.initialize(
            applicationId: "YOUR_APP_ID",
            clientKey: "YOUR_CLIENT_KEY",
            primaryKey: "YOUR_PRIMARY_KEY", // Only available server-side
            serverURL: URL(string: "https://your-parse-server.com/parse")!
        )

        // Create schemas during deployment
        await createRequiredSchemas()

        print("Database schemas initialized successfully!")
    } catch {
        print("Schema deployment failed: \(error)")
    }
}

func createRequiredSchemas() async {
    // Create all required schemas for your application
    // This ensures consistent database structure across environments

    // Example: Create a GameScore schema
    let clp = ParseCLP(requiresAuthentication: true, publicAccess: false)
        .setAccessPublic(true, on: .find)
        .setAccessPublic(true, on: .get)

    var gameScoreSchema = ParseSchema<GameScore>(classLevelPermissions: clp)
        .addField("points", type: .number,
                 options: ParseFieldOptions<Int>(required: false, defauleValue: nil))
        .addField("level", type: .number,
                 options: ParseFieldOptions<Int>(required: false, defauleValue: nil))

    do {
        _ = try await gameScoreSchema.create()
        print("GameScore schema created successfully")
    } catch {
        print("Failed to create GameScore schema: \(error)")
    }
}
