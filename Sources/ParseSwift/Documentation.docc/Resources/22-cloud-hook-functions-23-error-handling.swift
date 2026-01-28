import Vapor

// Implement proper error handling in your webhooks
func routes(_ app: Application) throws {
    app.post("foo") { req -> Response in
        do {
            struct WebhookRequest: Content {
                let params: [String: AnyCodable]
            }
            
            let webhookReq = try req.content.decode(WebhookRequest.self)
            
            // Validate input parameters
            guard let requiredParam = webhookReq.params["required"] else {
                // Return Parse error format
                let error = [
                    "code": 400,
                    "error": "Missing required parameter"
                ] as [String : Any]
                return try await error.encodeResponse(for: req)
            }
            
            // Process the request
            let result = processWebhook(requiredParam)
            
            // Return success
            return try await ["result": result].encodeResponse(for: req)
            
        } catch {
            // Log the error for debugging
            req.logger.error("Webhook error: \(error)")
            
            // Return error in Parse format
            let errorResponse = [
                "code": 141,
                "error": "Internal server error: \(error.localizedDescription)"
            ] as [String : Any]
            return try await errorResponse.encodeResponse(for: req)
        }
    }
}

func processWebhook(_ param: AnyCodable) -> String {
    return "Processed"
}
