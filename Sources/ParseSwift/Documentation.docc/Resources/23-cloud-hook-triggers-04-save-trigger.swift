import Foundation
import ParseSwift

// Create the trigger on Parse Server
Task {
    do {
        let savedTrigger = try await myTrigger.create()
        print("Trigger created successfully!")
        print("Trigger: \(savedTrigger)")
    } catch {
        print("Could not create trigger: \(error)")
    }
}
