import Vapor

// Handle webhook requests with appropriate timeouts
func routes(_ app: Application) throws {
    app.post("foo") { req -> Response in
        struct WebhookRequest: Content {
            let params: [String: AnyCodable]
        }
        
        let webhookReq = try req.content.decode(WebhookRequest.self)
        
        // For quick operations, process and return immediately
        if isQuickOperation(webhookReq.params) {
            let result = processQuickly(webhookReq.params)
            return try await ["result": result].encodeResponse(for: req)
        }
        
        // For long-running operations, start a background job
        // and return immediately
        Task {
            await processInBackground(webhookReq.params)
        }
        
        // Return success immediately
        return try await ["result": "Processing started"].encodeResponse(for: req)
    }
}

func isQuickOperation(_ params: [String: AnyCodable]) -> Bool {
    // Check if this operation can complete quickly
    return true
}

func processQuickly(_ params: [String: AnyCodable]) -> String {
    return "Quick result"
}

func processInBackground(_ params: [String: AnyCodable]) async {
    // Long-running operation
}
