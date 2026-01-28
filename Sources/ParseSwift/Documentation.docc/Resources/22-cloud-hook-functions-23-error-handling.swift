import Vapor

// Implement proper error handling in your webhooks
func routes(_ app: Application) throws {
    app.post("foo") { req async throws in
        struct WebhookRequest: Content {
            let params: [String: String]
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
                return error
            }
            
            // Process the request
            let result = processWebhook(requiredParam)
            
            // Return success
            return SuccessResponse(result: result)
            
        } catch {
            // Log the error for debugging
            req.logger.error("Webhook error: \(error)")
            
            // Return error in Parse format
            let errorResponse = ErrorResponse(
                code: 141,
                error: "Internal server error: \(error.localizedDescription)"
            )
            return errorResponse
        }
    }
}

func processWebhook(_ param: String) -> String {
    return "Processed"
}
