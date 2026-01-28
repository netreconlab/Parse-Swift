import Foundation
import ParseSwift

// Implement comprehensive error handling for trigger operations
Task {
    do {
        let trigger = ParseHookTrigger(
            object: gameScore,
            trigger: .afterSave,
            url: URL(string: "https://api.example.com/webhook")!
        )
        
        let savedTrigger = try await trigger.create()
        print("Trigger created: \(savedTrigger)")
        
    } catch let error as ParseError {
        // Handle Parse-specific errors
        switch error.code {
        case .objectNotFound:
            print("Trigger not found")
        case .connectionFailed:
            print("Network connection failed")
        default:
            print("Parse error: \(error.message)")
        }
    } catch {
        print("Unexpected error: \(error)")
    }
}
