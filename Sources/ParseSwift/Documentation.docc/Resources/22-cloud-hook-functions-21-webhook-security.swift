import Vapor

/// Timing-safe comparison to prevent timing attacks
private func timingSafeEquals(_ lhs: String, _ rhs: String) -> Bool {
    let lhsScalars = Array(lhs.unicodeScalars)
    let rhsScalars = Array(rhs.unicodeScalars)
    
    guard lhsScalars.count == rhsScalars.count else {
        return false
    }
    
    var result: UInt32 = 0
    for i in 0..<lhsScalars.count {
        result |= lhsScalars[i].value ^ rhsScalars[i].value
    }
    
    return result == 0
}

// Secure your webhook endpoints with authentication
func routes(_ app: Application) throws {
    app.post("foo") { req async throws in
        // Verify the request is from Parse Server using a shared secret
        guard
            let expectedSecret = Environment.get("PARSE_WEBHOOK_SECRET"),
            !expectedSecret.isEmpty,
            let providedSecret = req.headers.first(name: "X-Parse-Webhook-Secret"),
            timingSafeEquals(providedSecret, expectedSecret)
        else {
            throw Abort(.unauthorized, reason: "Invalid webhook signature")
        }
        
        // Verify the application ID as an additional check
        guard let appId = req.headers.first(name: "X-Parse-Application-Id"),
              appId == Environment.get("PARSE_APPLICATION_ID") else {
            throw Abort(.unauthorized, reason: "Invalid application ID")
        }
        
        // Process the webhook request
        struct WebhookRequest: Content {
            let params: [String: String]
        }
        
        let webhookReq = try req.content.decode(WebhookRequest.self)
        
        // Your business logic here
        struct SuccessResponse: Content {
            let result: String
        }
        return SuccessResponse(result: "Success")
    }
}
