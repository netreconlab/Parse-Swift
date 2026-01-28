/*
 ⚠️ SECURITY WARNING ⚠️
 
 Hook Function management requires the Parse Server primary key.
 NEVER use the primary key in client applications.
 
 ❌ DO NOT do this in client apps:
 ParseSwift.initialize(
     applicationId: "myAppId",
     primaryKey: "myPrimaryKey", // DON'T DO THIS!
     serverURL: URL(string: "https://api.example.com/parse")!
 )
 
 ✅ Only use Hook Functions in server-side environments:
 - ParseServerSwift
 - Vapor server
 - Kitura server
 - Other backend frameworks
 
 Use environment variables to store the primary key securely.
 */
