import Vapor

// Implement proper error handling in your webhooks
func routes(_ app: Application) throws {
    app.post("foo") { req async throws -> Response in
        struct WebhookRequest: Content {
            let params: [String: AnyCodable]
        }
        
        struct SuccessResponse: Content {
            let result: String
        }
        
        struct ErrorResponse: Content {
            let code: Int
            let error: String
        }
        
        do {
            let webhookReq = try req.content.decode(WebhookRequest.self)
            
            // Validate input parameters
            guard let requiredParam = webhookReq.params["required"] else {
                // Return Parse error format
                let error = ErrorResponse(code: 400, error: "Missing required parameter")
                return try await error.encodeResponse(for: req)
            }
            
            // Process the request
            let result = processWebhook(requiredParam)
            
            // Return success
            return try await SuccessResponse(result: result).encodeResponse(for: req)
            
        } catch {
            // Log the error for debugging
            req.logger.error("Webhook error: \(error)")
            
            // Return error in Parse format
            let errorResponse = ErrorResponse(
                code: 141,
                error: "Internal server error: \(error.localizedDescription)"
            )
            return try await errorResponse.encodeResponse(for: req)
        }
    }
}

func processWebhook(_ param: AnyCodable) -> String {
    return "Processed"
}
