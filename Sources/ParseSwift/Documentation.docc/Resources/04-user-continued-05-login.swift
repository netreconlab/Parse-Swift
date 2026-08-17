import Foundation
import ParseSwift

Task {
    do {
        let loggedInUser = try await User.login(username: "hello", password: "TestMePass123^")
        print("Successfully logged in as user: \(loggedInUser)")
    } catch {
        print("Error logging in: \(error)")
    }
}
