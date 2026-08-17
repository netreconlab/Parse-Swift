import Foundation
import ParseSwift

// ❌ NEVER do this - embedding primary key in client apps
// This is a critical security vulnerability!
// Parse.initialize(
//     applicationId: "your-app-id",
//     clientKey: "your-client-key",
//     serverURL: URL(string: "https://your-server.com")!,
//     primaryKey: "YOUR_PRIMARY_KEY" // ❌ NEVER include this in client apps!
// )

// ✅ Only use schema operations in secure server-side environments:
// - Server-side Swift frameworks (Vapor, Kitura, etc.)
// - Backend deployment scripts
// - Admin tools running in secure environments
// - CI/CD pipelines for database migrations

// Schema operations should only be used from:
// 1. Server-side Swift applications
// 2. Database migration scripts
// 3. Admin tools with restricted access
// 4. Deployment automation in secure environments
